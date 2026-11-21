classdef ProtocolDef
% ScapyML.ProtocolDef  Defines the layout of one C struct as a network protocol.
%
% Created by ScapyML.HeaderParser or programmatically.
% Used by Packet to encode/decode binary data and to generate dissectors.

    properties
        Name        (1,:) char = ''   % MATLAB/Wireshark protocol name
        CName       (1,:) char = ''   % Original C typedef name
        Fields      (:,1) cell = {}   % cell array of ScapyML.FieldDef or nested ProtocolDef
        Endian      (1,:) char = 'little'  % default endianness
        Description (1,:) char = ''
        TotalBits   (1,1) double = 0  % computed after all fields added
        IsUnion     (1,1) logical = false  % true for union types (members overlap at offset 0)
    end

    methods
        function obj = ProtocolDef(name, endian)
            if nargin == 0, return; end
            obj.Name  = name;
            obj.CName = name;
            if nargin >= 2
                obj.Endian = endian;
            end
        end

        function obj = addField(obj, fieldDef)
            % Append a FieldDef (or nested ProtocolDef flattened) to the list
            obj.Fields{end+1} = fieldDef;
            obj = obj.recompute();
        end

        function obj = recompute(obj)
            % Recalculate TotalBits from the field list.
            %
            % For unions:  TotalBits = MAX member size (all members overlap at offset 0).
            % For structs: TotalBits = SUM of member sizes (packed, no padding).
            %
            % Layout is ALWAYS PACKED: no alignment padding is inserted
            %   (see fieldAlignBytes), so a struct's size is the sum of its members.
            total = 0;

            for k = 1:numel(obj.Fields)
                f = obj.Fields{k};

                if isa(f, 'ScapyML.FieldDef')
                    if f.IsBitField
                        % Bitfields pack consecutively within their storage unit;
                        % no inter-field padding is inserted for individual bits.
                        memberBits  = f.BitSize;
                        alignBits   = 0;  % packing handled by bit-level accumulation
                    else
                        elemBytes  = f.ByteSize;
                        alignBytes = ScapyML.ProtocolDef.fieldAlignBytes(f);
                        alignBits  = alignBytes * 8;

                        if ~obj.IsUnion && alignBits > 0
                            % Advance total to the next alignment boundary
                            rem = mod(total, alignBits);
                            if rem ~= 0
                                total = total + (alignBits - rem);
                            end
                        end

                        memberBits = elemBytes * 8;
                        if f.IsArray && f.ArraySize > 1
                            memberBits = memberBits * f.ArraySize;
                        end
                    end

                elseif isa(f, 'ScapyML.ProtocolDef')
                    % Nested struct/union: align to its largest-member alignment
                    memberBits = f.TotalBits;
                    if ~obj.IsUnion && memberBits > 0
                        alignBits = ScapyML.ProtocolDef.structAlignBits(f);
                        rem = mod(total, alignBits);
                        if rem ~= 0
                            total = total + (alignBits - rem);
                        end
                    end
                else
                    memberBits = 0;
                end

                if obj.IsUnion
                    total = max(total, memberBits);
                else
                    total = total + memberBits;
                end
            end

            % Structs also get trailing padding so their size is a multiple
            % of the largest alignment requirement (C ABI trailing pad rule)
            if ~obj.IsUnion && ~isempty(obj.Fields)
                maxAlign = ScapyML.ProtocolDef.structAlignBits(obj);
                if maxAlign > 0
                    rem = mod(total, maxAlign);
                    if rem ~= 0
                        total = total + (maxAlign - rem);
                    end
                end
            end

            obj.TotalBits = total;
        end

        function n = totalBytes(obj)
            n = ceil(obj.TotalBits / 8);
        end

        function names = fieldNames(obj)
            % Return flat list of field names (depth-first for nested structs)
            names = {};
            for k = 1:numel(obj.Fields)
                f = obj.Fields{k};
                if isa(f,'ScapyML.FieldDef')
                    names{end+1} = f.Name; %#ok<AGROW>
                elseif isa(f,'ScapyML.ProtocolDef')
                    sub = f.fieldNames();
                    names = [names, sub]; %#ok<AGROW>
                end
            end
        end
        
        function offsets = getFieldOffsets(obj)
            % Return byte offset for each field (matches Codec encoding logic)
            % Returns: cell array of structs with fields:
            %   .name - field name
            %   .byteOffset - byte offset
            %   .bitOffset - bit offset within byte (for bit-fields)
            %   .sizeBytes - size in bytes
            offsets = {};
            collectOffsets(obj.Fields, 0, obj.IsUnion);
            
            function collectOffsets(fields, startBit, isUnion)
                bitPos = startBit;
                for i = 1:numel(fields)
                    f = fields{i};
                    
                    if isa(f, 'ScapyML.ProtocolDef')
                        % Nested structure — align start position (v2.3.1, KI-001)
                        if isUnion
                            childStart = startBit;
                        else
                            alignBits = ScapyML.ProtocolDef.structAlignBits(f);
                            bitPos = ScapyML.ProtocolDef.alignBitPos(bitPos, alignBits);
                            childStart = bitPos;
                        end
                        collectOffsets(f.Fields, childStart, f.IsUnion);
                        if ~isUnion
                            bitPos = bitPos + f.TotalBits;
                        end
                    elseif isa(f, 'ScapyML.FieldDef')
                        % Regular field — align start position, except
                        % bit-fields (which pack with no inter-field
                        % padding) and members of a union (v2.3.1, KI-001)
                        if isUnion
                            fieldStart = startBit;
                        else
                            if ~f.IsBitField
                                alignBits = ScapyML.ProtocolDef.fieldAlignBytes(f) * 8;
                                bitPos = ScapyML.ProtocolDef.alignBitPos(bitPos, alignBits);
                            end
                            fieldStart = bitPos;
                        end

                        info = struct();
                        info.name = f.Name;
                        info.displayName = f.displayName();   % full name for display
                        info.byteOffset = floor(fieldStart / 8);
                        info.bitOffset = mod(fieldStart, 8);
                        info.type = f.CType;
                        info.isBitField = f.IsBitField;
                        info.isArray = f.IsArray;
                        
                        if f.IsBitField
                            info.bitSize = f.BitSize;
                            info.sizeBytes = ceil(f.BitSize / 8);
                            fieldBits = f.BitSize;
                        else
                            info.sizeBytes = f.ByteSize;
                            fieldBits = f.ByteSize * 8;
                        end
                        
                        if f.IsArray
                            info.arraySize = f.ArraySize;
                            info.sizeBytes = info.sizeBytes * f.ArraySize;
                            fieldBits = fieldBits * f.ArraySize;
                        end
                        
                        offsets{end+1} = info; %#ok<AGROW>
                        
                        if ~isUnion
                            bitPos = fieldStart + fieldBits;
                        end
                    end
                end
            end
        end
    end

    methods (Static)
        function a = fieldAlignBytes(~)
            % ALWAYS PACKED: ScapyML lays out fields back to back with no
            % alignment padding (wire-protocol layout), e.g.
            %   { uint8_t a; uint8_t b; uint32_t c; }  ->  c at byte 2, size 6.
            % Every layout computation (recompute, getFieldOffsets, Codec,
            % Wireshark generator) goes through this one function.
            a = 1;
        end

        function a = alignmentOf(byteSize)
            % Natural alignment for a field of byteSize bytes.
            % Follows standard C ABI: align to min(byteSize, 8).
            % Bitfields are handled separately (no inter-field padding).
            if byteSize >= 8, a = 8;
            elseif byteSize >= 4, a = 4;
            elseif byteSize >= 2, a = 2;
            else, a = 1;
            end
        end

        function newBitPos = alignBitPos(bitPos, alignBits)
            % Round bitPos UP to the next multiple of alignBits.
            % alignBits <= 0 means "no alignment requirement" (e.g. bit-fields).
            %
            % Fixed v2.3.1 (KI-001): this helper is now the SINGLE shared
            % implementation of the alignment rule used by
            % ProtocolDef.recompute(), Codec.encodeFields/decodeFields,
            % ProtocolDef.getFieldOffsets(), and
            % WiresharkDissector.emitFieldList/collectFieldsWithMeta.
            % Previously only recompute() applied alignment padding, so
            % totalBytes() reported a C-ABI-correct size while the actual
            % field PLACEMENT logic in the other four locations still
            % packed fields with no padding — silently corrupting the
            % layout for any struct with mixed field sizes.
            if alignBits <= 0
                newBitPos = bitPos;
                return;
            end
            rem = mod(bitPos, alignBits);
            if rem ~= 0
                newBitPos = bitPos + (alignBits - rem);
            else
                newBitPos = bitPos;
            end
        end

        function alignBits = structAlignBits(protoDef)
            % Alignment requirement of a struct = alignment of its largest member.
            % Used for both inter-struct padding and trailing pad computation.
            maxAlign = 1;
            for k = 1:numel(protoDef.Fields)
                f = protoDef.Fields{k};
                if isa(f, 'ScapyML.FieldDef') && ~f.IsBitField
                    maxAlign = max(maxAlign, ScapyML.ProtocolDef.fieldAlignBytes(f));
                elseif isa(f, 'ScapyML.ProtocolDef')
                    maxAlign = max(maxAlign, ScapyML.ProtocolDef.structAlignBits(f) / 8);
                end
            end
            alignBits = maxAlign * 8;
        end
    end
end
