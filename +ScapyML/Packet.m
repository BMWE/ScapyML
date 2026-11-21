classdef Packet < handle
% ScapyML.Packet  A live protocol packet instance - analogous to Scapy's Packet.
%
% Quick start:
%   pkt = ScapyML.Packet('MyProtocol');
%   pkt.set('fieldName', 42);
%   pkt.set('otherField', 7);
%   bytes = pkt.build();
%   pkt.show();
%
% Chaining (like Scapy's / operator):
%   outer = ScapyML.Packet('Header');
%   inner = ScapyML.Packet('Payload');
%   combined = outer.chain(inner);
%   bytes = combined.build();
%
% Decoding:
%   pkt2 = ScapyML.Packet.fromBytes('MyProtocol', bytes);

    properties (Access = private)
        Proto    % ScapyML.ProtocolDef
        Values   % struct of field values
        Dirty    % containers.Map: field names explicitly set by user
        Next     % ScapyML.Packet or []  (chained payload)
    end

    methods

        function obj = Packet(protoNameOrDef, varargin)
            % Constructor.  Accepts a protocol name (string) or ProtocolDef.
            %
            % Internal fast path (bulk loaders only):
            %   Packet(protoDef, '__values__', valuesStruct)
            % skips the field-tree traversal and the Dirty-map creation.
            if nargin == 3 && isa(protoNameOrDef,'ScapyML.ProtocolDef') && ...
                    ischar(varargin{1}) && strcmp(varargin{1},'__values__')
                obj.Proto  = protoNameOrDef;
                obj.Values = varargin{2};
                obj.Dirty  = [];     % created lazily by set()
                obj.Next   = [];
                return;
            end
            if ischar(protoNameOrDef) || isstring(protoNameOrDef)
                obj.Proto = ScapyML.ProtocolRegistry.instance().get(char(protoNameOrDef));
            elseif isa(protoNameOrDef,'ScapyML.ProtocolDef')
                obj.Proto = protoNameOrDef;
            else
                error('ScapyML:Packet:BadArg','Expected protocol name or ProtocolDef');
            end

            % Initialise all fields to their defaults (traverse full field tree)
            obj.Values = struct();
            obj.Dirty  = containers.Map('KeyType','char','ValueType','logical');
            allFields  = ScapyML.Packet.collectFields(obj.Proto.Fields);
            for k = 1:numel(allFields)
                f = allFields{k};
                obj.Values.(f.Name) = f.DefaultVal;
            end
            obj.Next = [];

            % Optional: set field pairs  Packet('P', 'f1', v1, 'f2', v2)
            for k = 1 : 2 : numel(varargin)-1
                obj.set(varargin{k}, varargin{k+1});
            end
        end

        % ----------------------------------------------------------------
        % Field accessors
        % ----------------------------------------------------------------

        function obj = set(obj, fieldName, value)
            % Assign a value to a named field with validation
            
            if ~isfield(obj.Values, fieldName)
                error('ScapyML:Packet:UnknownField', ...
                    'Field "%s" not found in protocol "%s".\nValid fields: %s', ...
                    fieldName, obj.Proto.Name, ...
                    strjoin(fieldnames(obj.Values)', ', '));
            end
            
            % Get field definition for validation
            fd = obj.findField(fieldName);
            if ~isempty(fd)
                % Validate type
                if ~isnumeric(value)
                    error('ScapyML:Packet:InvalidType', ...
                        'Field %s requires numeric value, got %s', fieldName, class(value));
                end
                
                % Handle arrays
                if fd.IsArray
                    if numel(value) > fd.ArraySize
                        warning('ScapyML:Packet:ArrayTruncated', ...
                            'Truncating value for %s: %d -> %d elements', ...
                            fieldName, numel(value), fd.ArraySize);
                        value = value(1:fd.ArraySize);
                    elseif numel(value) < fd.ArraySize
                        % Pad with zeros
                        value = [value(:)', zeros(1, fd.ArraySize - numel(value))];
                    end
                else
                    % Single value field
                    if numel(value) > 1
                        warning('ScapyML:Packet:NotArray', ...
                            'Field %s is not an array, taking first element', fieldName);
                        value = value(1);
                    end
                end
                
                % Range checking and type conversion for integer types
                if ~fd.IsBitField && ~strcmp(fd.CType, 'float') && ~strcmp(fd.CType, 'double')
                    % Determine if signed or unsigned
                    % CRITICAL: Must handle all C integer types correctly
                    
                    ctype = lower(fd.CType);  % Case-insensitive comparison
                    
                    % UNSIGNED if contains 'unsigned' or 'uint' or is known unsigned type
                    if contains(ctype, 'unsigned') || ...
                       contains(fd.CType, 'uint') || ...  % Preserve case for uint_t
                       strcmp(ctype, 'byte') || strcmp(ctype, 'word') || ...
                       strcmp(ctype, 'dword') || strcmp(ctype, 'qword') || ...
                       strcmp(ctype, 'size_t') || strcmp(ctype, 'uintptr_t') || ...
                       startsWith(ctype, 'u_') || startsWith(ctype, 'u8') || ...
                       startsWith(ctype, 'u16') || startsWith(ctype, 'u32') || ...
                       startsWith(ctype, 'u64')
                        isSigned = false;
                    
                    % SIGNED if contains 'int' (but not 'uint'), or is short/long/char variant
                    elseif (contains(fd.CType, 'int') && ~contains(fd.CType, 'uint')) || ...
                           contains(ctype, 'short') || contains(ctype, 'long') || ...
                           startsWith(ctype, 'signed') || ...
                           strcmp(ctype, 'signed') || ...
                           startsWith(ctype, 's8') || startsWith(ctype, 's16') || ...
                           startsWith(ctype, 's32') || startsWith(ctype, 's64') || ...
                           startsWith(ctype, 'sint')
                        isSigned = true;
                    
                    % CHAR: Treat 'signed char' as signed, plain 'char' as signed (x86 convention)
                    elseif contains(ctype, 'char')
                        % 'signed char' → signed, 'unsigned char' already handled above
                        % plain 'char' → treat as signed (x86/most platforms)
                        isSigned = ~contains(ctype, 'unsigned');
                    
                    % DEFAULT: For unknown types, assume unsigned for safety
                    else
                        isSigned = false;
                    end
                    
                    % Apply range checking and clamping based on type
                    if fd.ByteSize == 1
                        if isSigned  % int8
                            minVal = -128;
                            maxVal = 127;
                            if any(value < minVal) || any(value > maxVal)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (int8) out of range [%d,%d], clamping', ...
                                    fieldName, minVal, maxVal);
                                value = max(minVal, min(maxVal, value));
                            end
                        else  % uint8
                            if any(value < 0) || any(value > 255)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (uint8) out of range [0,255], clamping', fieldName);
                                value = max(0, min(255, value));
                            end
                        end
                        
                    elseif fd.ByteSize == 2
                        if isSigned  % int16
                            minVal = -32768;
                            maxVal = 32767;
                            if any(value < minVal) || any(value > maxVal)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (int16) out of range [%d,%d], clamping', ...
                                    fieldName, minVal, maxVal);
                                value = max(minVal, min(maxVal, value));
                            end
                        else  % uint16
                            if any(value < 0) || any(value > 65535)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (uint16) out of range [0,65535], clamping', fieldName);
                                value = max(0, min(65535, value));
                            end
                        end
                        
                    elseif fd.ByteSize == 4
                        if isSigned  % int32
                            minVal = -2147483648;
                            maxVal = 2147483647;
                            if any(value < minVal) || any(value > maxVal)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (int32) out of range [%d,%d], clamping', ...
                                    fieldName, minVal, maxVal);
                                value = max(minVal, min(maxVal, value));
                            end
                        else  % uint32
                            if any(value < 0) || any(value > 4294967295)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (uint32) out of range [0,4294967295], clamping', fieldName);
                                value = max(0, min(4294967295, value));
                            end
                        end
                        
                    elseif fd.ByteSize == 8
                        if isSigned  % int64
                            minVal = -9223372036854775808;
                            maxVal = 9223372036854775807;
                            if any(value < minVal) || any(value > maxVal)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (int64) out of range [%d,%d], clamping', ...
                                    fieldName, minVal, maxVal);
                                value = max(minVal, min(maxVal, value));
                            end
                        else  % uint64
                            if any(value < 0) || any(value > 18446744073709551615)
                                warning('ScapyML:Packet:OutOfRange', ...
                                    'Value for %s (uint64) out of range [0,18446744073709551615], clamping', fieldName);
                                value = max(0, min(18446744073709551615, value));
                            end
                        end
                    end
                end
            end
            
            obj.Values.(fieldName) = value;
            if ~isa(obj.Dirty,'containers.Map')   % lazily created (bulk fast path)
                obj.Dirty = containers.Map('KeyType','char','ValueType','logical');
            end
            obj.Dirty(fieldName)   = true;
        end

        function val = get(obj, fieldName)
            if isfield(obj.Values, fieldName)
                val = obj.Values.(fieldName);
            else
                error('ScapyML:Packet:UnknownField','Field "%s" not found.', fieldName);
            end
        end
        
        function names = fieldNames(obj)
            % Return all field names in the packet
            names = fieldnames(obj.Values);
        end

        function loadStruct(obj, s)
            % Load values from a struct (only copies fields that exist in proto).
            fns = fieldnames(s);
            for k = 1:numel(fns)
                if isfield(obj.Values, fns{k})
                    obj.Values.(fns{k}) = s.(fns{k});
                end
            end
        end

        % ----------------------------------------------------------------
        % Build / encode
        % ----------------------------------------------------------------

        function bytes = build(obj)
            % Encode this packet (and any chained payloads) to a byte array.
            bytes = ScapyML.Codec.encode(obj.Proto, obj.Values, obj.Dirty);
            if ~isempty(obj.Next)
                bytes = [bytes, obj.Next.build()];
            end
        end
        
        function bytes = buildWithChecksums(obj, checksumManager)
            % Build packet and apply checksums to raw bytes
            %
            % ARGUMENTS:
            %   checksumManager - ScapyML.ChecksumManager object
            %
            % RETURNS:
            %   bytes - uint8 array with checksums calculated and written
            %
            % USAGE:
            %   cm = ScapyML.ChecksumManager('checksums.txt');
            %   binary = pkt.buildWithChecksums(cm);
            %
            % PROCESS:
            %   1. Encode packet normally (checksum fields should be 0)
            %   2. Calculate checksums from raw bytes
            %   3. Write checksum values back into byte array
            %   4. Return final bytes ready for transmission
            
            % First encode normally
            bytes = obj.build();
            
            % Apply checksums to raw bytes
            bytes = checksumManager.applyChecksums(bytes, obj);
        end

        % ----------------------------------------------------------------
        % Protocol introspection (public access without exposing Proto)
        % ----------------------------------------------------------------

        function offsets = getFieldOffsets(obj)
            % Return field offset table from the underlying ProtocolDef.
            % Used by ChecksumManager (and any other component that needs
            % byte-level field positions) without exposing the private Proto.
            offsets = obj.Proto.getFieldOffsets();
        end

        function name = getProtocolName(obj)
            % Return the protocol name string.
            name = obj.Proto.Name;
        end

        function endian = getEndian(obj)
            % Return endianness string ('big' or 'little') from the ProtocolDef.
            endian = obj.Proto.Endian;
        end

        % ----------------------------------------------------------------
        % Decode
        % ----------------------------------------------------------------

        function obj = fromRaw(obj, bytes)
            % Populate fields from raw byte array.
            obj.Values = ScapyML.Codec.decode(obj.Proto, bytes);
        end

        % ----------------------------------------------------------------
        % Chaining
        % ----------------------------------------------------------------

        function combined = chain(obj, nextPkt)
            % Chain another Packet as the payload (like Scapy's /).
            combined     = obj;
            tail         = obj;
            while ~isempty(tail.Next)
                tail = tail.Next;
            end
            tail.Next = nextPkt;
        end

        % ----------------------------------------------------------------
        % Human-readable display
        % ----------------------------------------------------------------

        function s = displayName(obj, fname)
            % Full (unshortened) name of a field, for display. The short
            % name returned by fieldNames() remains the key for set/get.
            fd = obj.findField(fname);
            if ~isempty(fd)
                s = fd.displayName();
            else
                s = fname;
            end
        end

        function show(obj)
            fprintf('\n=== Packet: %s ===\n', obj.Proto.Name);
            fns = fieldnames(obj.Values);
            % Show full (unshortened) names; column wide enough for the longest
            nameW = 30;
            for k = 1:numel(fns)
                nameW = max(nameW, numel(obj.displayName(fns{k})));
            end
            for k = 1:numel(fns)
                fn  = fns{k};
                val = obj.Values.(fn);
                % Find field def for description, type info, and CType
                fd  = obj.findField(fn);
                if ~isempty(fd) && fd.IsBitField
                    typeStr = sprintf('[%d-bit]', fd.BitSize);
                else
                    typeStr = '';
                end
                descr = '';
                if ~isempty(fd) && ~isempty(fd.Description)
                    descr = sprintf('  // %s', fd.Description);
                end
                % Pass fd so fmtVal can format floats/doubles correctly
                fprintf('  %-*s = %-28s %s%s\n', nameW, obj.displayName(fn), ...
                    ScapyML.Packet.fmtVal(val, fd), typeStr, descr);
            end
            if ~isempty(obj.Next)
                obj.Next.show();
            end
            fprintf('\n  [Total raw bytes: %d]\n', numel(obj.build()));
        end

        function hexdump(obj)
            % Print hex dump of the built packet.
            bytes = obj.build();
            fprintf('\nHex dump (%d bytes):\n', numel(bytes));
            for i = 1:numel(bytes)
                fprintf('%02X ', bytes(i));
                if mod(i,16) == 0, fprintf('\n'); end
            end
            fprintf('\n');
        end

    end

    methods (Static)

        function pkt = fromBytes(protoName, bytes)
            % Decode bytes into a Packet.
            pkt = ScapyML.Packet(protoName);
            pkt.fromRaw(bytes);
        end

        function pkt = fromValuesStruct(protoDef, defaultValues, overrides)
            % Fast bulk constructor: bypass registry lookup, field traversal,
            % and per-field validation. Used by bulk CSV loading.
            %
            % protoDef      - ScapyML.ProtocolDef (resolved once outside the loop)
            % defaultValues - struct with all fields pre-initialised to defaults
            % overrides     - struct of fieldName->value to apply on top
            vals   = defaultValues;
            fields = fieldnames(overrides);
            for k = 1:numel(fields)
                fn = fields{k};
                if isfield(vals, fn)
                    vals.(fn) = overrides.(fn);
                end
            end
            pkt = ScapyML.Packet(protoDef, '__values__', vals);
        end

        function pkt = fromValues(protoDef, values)
            % Fastest bulk constructor: 'values' is a complete Values struct
            % (all fields already resolved). No validation, no traversal.
            pkt = ScapyML.Packet(protoDef, '__values__', values);
        end

        function fields = collectFields(fieldList)
            % Depth-first collect all FieldDef objects from a field tree.
            % Public so bulk loaders can build the default Values struct
            % without constructing a full Packet instance.
            fields = {};
            for k = 1:numel(fieldList)
                f = fieldList{k};
                if isa(f,'ScapyML.FieldDef')
                    fields{end+1} = f; %#ok<AGROW>
                elseif isa(f,'ScapyML.ProtocolDef')
                    sub = ScapyML.Packet.collectFields(f.Fields);
                    fields = [fields, sub]; %#ok<AGROW>
                end
            end
        end

    end

    methods (Access = private)

        function fd = findField(obj, name)
            % Recursively search all fields (including nested ProtocolDef children)
            fd = ScapyML.Packet.findFieldIn(obj.Proto.Fields, name);
        end

    end

    methods (Static, Access = private)

        function fd = findFieldIn(fieldList, name)
            % Depth-first search for a FieldDef by name in a field tree.
            fd = [];
            for k = 1:numel(fieldList)
                f = fieldList{k};
                if isa(f,'ScapyML.FieldDef') && strcmp(f.Name, name)
                    fd = f; return;
                elseif isa(f,'ScapyML.ProtocolDef')
                    fd = ScapyML.Packet.findFieldIn(f.Fields, name);
                    if ~isempty(fd), return; end
                end
            end
        end

        function s = fmtVal(v, fd)
            % Format a field value for display.
            % fd (optional FieldDef) is used to detect float/double types.
            % Check if it's an array
            if ~isempty(fd) && fd.IsArray && numel(v) > 1
                % Format as array
                if numel(v) <= 8
                    % Short array: show all elements
                    s = '[';
                    for i = 1:numel(v)
                        if strcmp(fd.CType, 'float') || strcmp(fd.CType, 'double')
                            s = [s sprintf('%.4g', v(i))];
                        else
                            s = [s sprintf('%d', v(i))];
                        end
                        if i < numel(v), s = [s ', ']; end
                    end
                    s = [s ']  (' num2str(numel(v)) ' elements)'];
                else
                    % Long array: show first few + summary
                    s = '[';
                    for i = 1:min(3, numel(v))
                        if strcmp(fd.CType, 'float') || strcmp(fd.CType, 'double')
                            s = [s sprintf('%.4g', v(i))];
                        else
                            s = [s sprintf('%d', v(i))];
                        end
                        s = [s ', '];
                    end
                    s = [s '... ' num2str(numel(v)) ' elements]'];
                end
                return;
            end

            isFloatType = false;
            isDoubleType = false;
            if nargin >= 2 && ~isempty(fd) && isa(fd,'ScapyML.FieldDef')
                isFloatType  = strcmp(fd.CType,'float');
                isDoubleType = strcmp(fd.CType,'double');
            end

            if numel(v) ~= 1
                s = mat2str(v);
                return;
            end

            if isFloatType
                % Show value in full float precision + IEEE 754 hex (4 bytes)
                rawBytes = typecast(single(v), 'uint8');  % little-endian
                ieeeHex = sprintf('%02X%02X%02X%02X', ...
                    rawBytes(4), rawBytes(3), rawBytes(2), rawBytes(1));
                s = sprintf('%.7g (IEEE754: 0x%s)', double(v), ieeeHex);
            elseif isDoubleType
                % Show value in full double precision + IEEE 754 hex (8 bytes)
                rawBytes = typecast(double(v), 'uint8');  % little-endian
                ieeeHex = sprintf('%02X%02X%02X%02X%02X%02X%02X%02X', ...
                    rawBytes(8), rawBytes(7), rawBytes(6), rawBytes(5), ...
                    rawBytes(4), rawBytes(3), rawBytes(2), rawBytes(1));
                s = sprintf('%.15g (IEEE754: 0x%s)', double(v), ieeeHex);
            else
                % Integer / bit-field: show decimal and hex
                s = sprintf('%d (0x%X)', v, uint64(v));
            end
        end
    end

end
