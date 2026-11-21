function varargout = ScapyML(varargin)
% ScapyML  Clean entry-point for the ScapyML protocol framework.
%
% ============================================================
% SYNOPSIS
% ============================================================
%
% LOAD HEADER FILE(S)
%   protos = ScapyML('load', 'header.h')
%   protos = ScapyML('load', 'header.h', 'big')
%   protos = ScapyML('load', {'file1.h', 'file2.h'}, 'big')
%   protos = ScapyML('load', 'file1.h', 'file2.h', 'big')
%   protos = ScapyML('load', {'file1.h', 'file2.h'}, 'big', 'auto')  % Auto-resolve dependencies
%
% CREATE PACKET
%   pkt = ScapyML('packet', 'MyProtocol')
%   pkt = ScapyML('packet', 'MyProtocol', 'field1', 42, 'field2', 7)
%
% READ CSV AND BUILD PACKETS
%   pkts = ScapyML('csv', 'data.csv', 'MyProtocol')
%
% SEND OVER UDP
%   ScapyML('send', pkt,  '10.10.10.10', 1234)       % single packet
%   ScapyML('send', pkts, '10.10.10.10', 1234)        % cell array
%   ScapyML('send', pkt)                              % uses default IP/port
%
% GENERATE WIRESHARK DISSECTOR
%   ScapyML('dissector', 'MyProtocol', 'my_proto.lua')
%   ScapyML('dissector', 'MyProtocol', 'my_proto.lua', 1234)  % with UDP port
%
% SHOW PROTOCOL LAYOUT
%   ScapyML('info', 'MyProtocol')
%
% LIST REGISTERED PROTOCOLS
%   ScapyML('list')
%
% ============================================================
% FULL WORKFLOW EXAMPLE
% ============================================================
%
%   % 1. Parse header
%   ScapyML('load', 'sensor_msg.h', 'big');
%
%   % 2. Build a packet manually
%   pkt = ScapyML('packet', 'SensorMsg', 'msg_id', 1, 'temperature', 235);
%   pkt.show();
%
%   % 3. Load from CSV and send
%   pkts = ScapyML('csv', 'sensor_data.csv', 'SensorMsg');
%   ScapyML('send', pkts, '10.10.10.10', 1234);
%
%   % 4. Generate Wireshark dissector
%   ScapyML('dissector', 'SensorMsg', 'sensor_msg.lua', 1234);
%
% ============================================================

    DEFAULT_IP   = '10.10.10.10';
    DEFAULT_PORT = 1234;

    if isempty(varargin)
        ScapyML_help();
        return;
    end

    cmd = lower(strtrim(varargin{1}));

    switch cmd

        % ---- load ----
        case {'load','parse','header'}
            assert(numel(varargin) >= 2, 'Usage: ScapyML(''load'', files [, endian] [, ''auto''])');
            
            % Check for 'auto' flag for automatic dependency resolution
            autoResolve = false;
            fileArgs = varargin(2:end);
            if numel(fileArgs) > 0 && ischar(fileArgs{end}) && strcmp(fileArgs{end}, 'auto')
                autoResolve = true;
                fileArgs = fileArgs(1:end-1);
            end
            
            % Determine endianness (last argument if it's 'big' or 'little')
            endian = 'little';
            if numel(fileArgs) > 0
                lastArg = fileArgs{end};
                if ischar(lastArg) && (strcmp(lastArg, 'big') || strcmp(lastArg, 'little'))
                    endian = lastArg;
                    fileArgs = fileArgs(1:end-1);
                end
            end
            
            % Collect file names (can be single file, cell array, or multiple arguments)
            files = {};
            for i = 1:numel(fileArgs)
                arg = fileArgs{i};
                if iscell(arg)
                    % Cell array of files
                    files = [files, arg(:)'];  %#ok<AGROW>
                elseif ischar(arg)
                    % Single file name
                    files{end+1} = arg;  %#ok<AGROW>
                end
            end
            
            % Automatic dependency resolution
            if autoResolve && numel(files) > 1
                fprintf('[ScapyML] Auto-resolving dependencies...\n');
                files = ScapyML.DependencyResolver.resolveOrder(files);
            end
            
            % Parse and register each file IMMEDIATELY, one at a time.
            %
            % Fixed v2.3.3: previously all files were parsed first, and
            % registration into ProtocolRegistry happened only in a
            % SEPARATE pass afterward. That meant a struct in file B
            % referencing an enum defined in file A could not see that
            % enum during file B's own parse (the registry was still
            % empty), silently producing a 0-byte field. Registering
            % immediately after each file's parse — combined with
            % DependencyResolver's ordering above — ensures every
            % cross-file type reference is visible by the time it's needed.
            reg = ScapyML.ProtocolRegistry.instance();
            allProtos = {};
            for i = 1:numel(files)
                fprintf('[ScapyML] Parsing: %s\n', files{i});
                protos = ScapyML.HeaderParser.parseFile(files{i}, endian);
                allProtos = [allProtos, protos]; %#ok<AGROW>

                for k = 1:numel(protos)
                    if isa(protos{k}, 'ScapyML.ProtocolDef')
                        reg.register(protos{k});
                        fprintf('[ScapyML] Registered protocol: %s  (%d bytes)\n', ...
                            protos{k}.Name, protos{k}.totalBytes());
                    elseif isa(protos{k}, 'ScapyML.EnumDef')
                        reg.registerEnum(protos{k});
                        fprintf('[ScapyML] Registered enum: %s  (%d values)\n', ...
                            protos{k}.Name, numel(protos{k}.allNames()));
                    end
                end
            end
            
            if nargout > 0
                varargout{1} = allProtos;
            end

        % ---- packet ----
        case {'packet','pkt','new'}
            assert(numel(varargin) >= 2, 'Usage: ScapyML(''packet'', ''ProtocolName'' [, ''field'', val, ...])');
            pkt = ScapyML.Packet(varargin{2}, varargin{3:end});
            varargout{1} = pkt;

        % ---- csv ----
        % NOTE (bug fix): 'fromcsv' was previously ALSO listed here, which
        % shadowed the dedicated 'fromCSV' case below (see ~line 250) since
        % MATLAB's switch/case always matches the FIRST case containing the
        % value. That caused ScapyML('fromCSV', protoName, csvFile, ...) to
        % silently misfire into CsvLoader.load(protoName, csvFile) -- the
        % arguments in the wrong order -- producing a confusing
        % "CSV file not found: <protocol name>" error instead of ever
        % reaching the defaults/conversions-aware implementation. Removed
        % here so 'fromCSV' now correctly reaches its own case.
        case {'csv','readcsv'}
            assert(numel(varargin) >= 3, 'Usage: ScapyML(''csv'', ''file.csv'', ''ProtocolName'')');
            pkts = ScapyML.CsvLoader.load(varargin{2}, varargin{3});
            fprintf('[ScapyML] Loaded %d packets from %s\n', numel(pkts), varargin{2});
            varargout{1} = pkts;

        % ---- send ----
        case {'send','udp','tx'}
            data = varargin{2};
            ip   = DEFAULT_IP;
            port = DEFAULT_PORT;
            if numel(varargin) >= 3, ip   = varargin{3}; end
            if numel(varargin) >= 4, port = varargin{4}; end

            if iscell(data)
                ScapyML.PacketSender.sendWithTiming(data, ip, port, 'single');
            elseif isa(data,'ScapyML.Packet')
                ScapyML.UdpSender.sendOnce(data.build(), ip, port);
            elseif isnumeric(data)
                ScapyML.UdpSender.sendOnce(data, ip, port);
            else
                error('ScapyML:BadArg','send: expected Packet, cell array, or byte array');
            end

        % ---- dissector ----
        case {'dissector','lua','wireshark'}
            assert(numel(varargin) >= 3, ...
                'Usage: ScapyML(''dissector'', ''ProtocolName'', ''out.lua'' [, udpPort])');
            protoName = varargin{2};
            outFile   = varargin{3};
            udpPort   = [];
            if numel(varargin) >= 4, udpPort = varargin{4}; end
            
            reg = ScapyML.ProtocolRegistry.instance();
            proto = reg.get(protoName);
            
            % Get all registered enums
            enumNames = reg.listEnums();
            enumDefs = {};
            for i = 1:numel(enumNames)
                enumDefs{i} = reg.getEnum(enumNames{i});
            end
            
            ScapyML.WiresharkDissector.generate(proto, outFile, udpPort, enumDefs);
            if nargout > 0
                varargout{1} = outFile;
            end

        % ---- info ----
        case {'info','show','describe'}
            assert(numel(varargin) >= 2,'Usage: ScapyML(''info'', ''ProtocolName'')');
            ScapyML_showProtoInfo(varargin{2});

        % ---- list ----
        case {'list','ls','protocols'}
            names = ScapyML.ProtocolRegistry.instance().list();
            if nargout > 0
                varargout{1} = names;
            else
                fprintf('[ScapyML] Registered protocols (%d):\n', numel(names));
                for k = 1:numel(names)
                    p = ScapyML.ProtocolRegistry.instance().get(names{k});
                    fprintf('  %-30s  %d fields, %d bytes\n', names{k}, numel(p.Fields), p.totalBytes());
                end
            end

        % ---- register (programmatic) ----

        % ---- defaults (create file) ----
        case {'defaults','createdefaults','makedefaults'}
            assert(numel(varargin) >= 3,...
                'Usage: ScapyML(''defaults'', ''ProtocolName'', ''file.txt'')');
            ScapyML.DefaultsManager.create(varargin{2}, varargin{3});

        % ---- loaddefaults (apply to packet) ----
        case {'loaddefaults','applydefaults'}
            assert(numel(varargin) >= 3,...
                'Usage: pkt = ScapyML(''loaddefaults'', pkt, ''file.txt'')');
            pkt = varargin{2};
            pkt = ScapyML.DefaultsManager.apply(pkt, varargin{3});
            if nargout > 0
                varargout{1} = pkt;
            end

        case {'register'}
            assert(numel(varargin) >= 2,'Usage: ScapyML(''register'', protoDef)');
            ScapyML.ProtocolRegistry.instance().register(varargin{2});


        % ---- fromCSV (automatic packet creation, with defaults/conversions) ----
        % (bug fix: previously unreachable via 'fromcsv'/'fromCSV' due to the
        % duplicate case label on the 'csv' block above; now reachable.)
        case {'fromcsv','csv2packets','autocsv'}
            assert(numel(varargin) >= 3,...
                'Usage: ScapyML(''fromCSV'', ''ProtocolName'', ''data.csv'' [, ''defaults.txt''] [, ''conversions.txt''])');
            protoName = varargin{2};
            csvFile = varargin{3};
            defaultsFile = '';
            conversionFile = '';
            if numel(varargin) >= 4, defaultsFile = varargin{4}; end
            if numel(varargin) >= 5, conversionFile = varargin{5}; end
            pkts = ScapyML_fromCSV(protoName, csvFile, defaultsFile, conversionFile);
            fprintf('[ScapyML] Created %d packets from %s\n', numel(pkts), csvFile);
            if nargout > 0
                varargout{1} = pkts;
            end

        otherwise
            if nargout > 0
                varargout{1} = [];
            end
            warning('ScapyML:UnknownCmd','Unknown command: %s', cmd);
            ScapyML_help();
    end
end

% ----------------------------------------------------------------
function ScapyML_help()
    fprintf('\nScapyML - MATLAB Scapy-like Protocol Framework\n');
    fprintf('-----------------------------------------------\n');
    fprintf('  ScapyML(''load'', files [, endian] [,''auto'']) - Parse header(s)\n');
    fprintf('  ScapyML(''packet'', Name [, f, v, ...])       - Create packet\n');
    fprintf('  ScapyML(''csv'', file.csv, Name)              - Load from CSV\n');
    fprintf('  ScapyML(''send'', pkt/pkts [, ip, port])      - Send UDP\n');
    fprintf('  ScapyML(''dissector'', Name, out.lua [,port]) - Wireshark LUA\n');
    fprintf('  ScapyML(''info'', Name)                       - Show layout\n');
    fprintf('  ScapyML(''defaults'', Name, file.txt)         - Create defaults file\n');
    fprintf('  ScapyML(''loaddefaults'', pkt, file.txt)      - Apply defaults to pkt\n');
    fprintf('  ScapyML(''list'')                             - List protocols\n\n');
end

function ScapyML_showProtoInfo(protoName)
    % Enhanced info display with byte offsets and full field details
    
    p = ScapyML.ProtocolRegistry.instance().get(protoName);
    fprintf('\nProtocol: %s  (%d total bytes)\n', p.Name, p.totalBytes());
    fprintf('Endian:   %s\n', p.Endian);
    if p.IsUnion
        fprintf('Type:     UNION (all members at offset 0)\n');
    else
        fprintf('Type:     STRUCT\n');
    end
    fprintf('\n');
    fprintf('%-4s %-7s %-32s %-16s %-12s %-20s %s\n', ...
        '#','Offset','Field Name','Type','Size','Mask/Range','Description');
    fprintf('%s\n', repmat('-',1,110));
    
    % Track bit offset throughout structure
    bitOffset = 0;
    idx = 1;
    
    for k = 1:numel(p.Fields)
        f = p.Fields{k};
        
        if isa(f,'ScapyML.FieldDef')
            % Regular field
            byteOffset = floor(bitOffset / 8);
            bitInByte = mod(bitOffset, 8);
            
            [sizeStr, maskStr] = formatFieldInfo(f, bitOffset, p.IsUnion);
            offsetStr = formatOffset(byteOffset, bitInByte, f.IsBitField);
            
            fprintf('%-4d %-7s %-32s %-16s %-12s %-20s %s\n', ...
                idx, offsetStr, f.displayName(), formatType(f), sizeStr, maskStr, f.Description);
            idx = idx + 1;
            
            if ~p.IsUnion
                if f.IsBitField
                    bitOffset = bitOffset + f.BitSize;
                else
                    bitOffset = bitOffset + f.ByteSize * 8;
                end
            end
            
        elseif isa(f,'ScapyML.ProtocolDef')
            % Nested struct or union
            byteOffset = floor(bitOffset / 8);
            
            typeStr = sprintf('%s (%s)', f.CName, ternary(f.IsUnion, 'union', 'struct'));
            sizeStr = sprintf('%d byte%s', f.totalBytes(), ternary(f.totalBytes()>1, 's', ''));
            
            fprintf('%-4d %-7d %-32s %-16s %-12s %-20s %s\n', ...
                idx, byteOffset, f.Name, typeStr, sizeStr, '', ...
                ternary(isempty(f.Description), 'Nested', f.Description));
            idx = idx + 1;
            
            % Show nested fields with their offsets
            subBitOffset = 0;
            allFields = getAllFieldsRecursive(f);
            for j = 1:numel(allFields)
                sf = allFields{j};
                
                % Calculate absolute offset for nested field
                if f.IsUnion
                    % Union: all members at same offset as parent
                    absOffset = bitOffset + subBitOffset;
                else
                    % Struct: relative to parent's start
                    absOffset = bitOffset + subBitOffset;
                end
                
                subByteOffset = floor(absOffset / 8);
                subBitInByte = mod(absOffset, 8);
                
                [subSizeStr, subMaskStr] = formatFieldInfo(sf, absOffset, f.IsUnion);
                subOffsetStr = formatOffset(subByteOffset, subBitInByte, sf.IsBitField);
                
                fprintf('     %-7s %-32s %-16s %-12s %-20s\n', ...
                    subOffsetStr, ['  ' sf.displayName()], formatType(sf), subSizeStr, subMaskStr);
                
                if ~f.IsUnion
                    if sf.IsBitField
                        subBitOffset = subBitOffset + sf.BitSize;
                    else
                        subBitOffset = subBitOffset + sf.ByteSize * 8;
                    end
                end
            end
            fprintf('\n');
            
            if ~p.IsUnion
                bitOffset = bitOffset + f.TotalBits;
            end
        end
    end
    
    % Summary
    allFieldNames = p.fieldNames();
    fprintf('%s\n', repmat('-',1,110));
    fprintf('Total flattened fields: %d\n', numel(allFieldNames));
    % Check if any fields are bit-fields (for note display)
    hasBitFields = false;
    allDefs = getAllFieldDefsRecursive(p);
    for i = 1:numel(allDefs)
        if allDefs{i}.IsBitField
            hasBitFields = true;
            break;
        end
    end
    if hasBitFields
        fprintf('Note: Bit-field offsets shown as byte.bit (e.g., 20.0 = byte 20, bit 0)\n');
    end
    fprintf('\n');
end

function allFieldDefs = getAllFieldDefsRecursive(proto)
    % Get all FieldDef objects recursively (for checking if any are bit-fields)
    allFieldDefs = {};
    for k = 1:numel(proto.Fields)
        f = proto.Fields{k};
        if isa(f, 'ScapyML.FieldDef')
            allFieldDefs{end+1} = f; %#ok<AGROW>
        elseif isa(f, 'ScapyML.ProtocolDef')
            subDefs = getAllFieldDefsRecursive(f);
            allFieldDefs = [allFieldDefs, subDefs]; %#ok<AGROW>
        end
    end
end

function allFields = getAllFieldsRecursive(proto)
    % Get all FieldDef objects recursively from a ProtocolDef
    allFields = {};
    for k = 1:numel(proto.Fields)
        f = proto.Fields{k};
        if isa(f, 'ScapyML.FieldDef')
            allFields{end+1} = f; %#ok<AGROW>
        elseif isa(f, 'ScapyML.ProtocolDef')
            subFields = getAllFieldsRecursive(f);
            allFields = [allFields, subFields]; %#ok<AGROW>
        end
    end
end

function offsetStr = formatOffset(byteOffset, bitInByte, isBitField)
    % Format offset string: byte or byte.bit for bit-fields
    if isBitField && bitInByte > 0
        offsetStr = sprintf('%d.%d', byteOffset, bitInByte);
    else
        offsetStr = sprintf('%d', byteOffset);
    end
end

function typeStr = formatType(f)
    % Format type string for display
    if f.IsBitField
        typeStr = sprintf('%s:%d', f.CType, f.BitSize);
    else
        typeStr = f.CType;
    end
end

function [sizeStr, maskStr] = formatFieldInfo(f, bitOffset, isUnion)
    % Format size and mask information for a field
    
    if f.IsBitField
        % Bit-field: show bit count and mask
        sizeStr = sprintf('%d bit%s', f.BitSize, ternary(f.BitSize>1, 's', ''));
        
        % Calculate byte offset and bit position within byte
        byteOff = floor(bitOffset / 8);
        bitPosInByte = mod(bitOffset, 8);
        
        % Calculate mask and bit position
        % Standard C: bit-fields pack from LSB upward
        % Bits are numbered from MSB (bit 7) to LSB (bit 0)
        startBit = bitPosInByte;  % First bit in field (LSB of field)
        endBit = startBit + f.BitSize - 1;  % Last bit in field (MSB of field)
        
        % Calculate mask value
        mask = 0;
        for b = startBit:endBit
            mask = bitor(mask, bitshift(1, b));
        end
        
        if f.BitSize == 1
            maskStr = sprintf('0x%02X (bit %d)', mask, startBit);
        else
            maskStr = sprintf('0x%02X (bits %d-%d)', mask, endBit, startBit);
        end
        
    elseif strcmp(f.CType, 'float')
        sizeStr = '4 bytes';
        maskStr = '±3.4e38';
        
    elseif strcmp(f.CType, 'double')
        sizeStr = '8 bytes';
        maskStr = '±1.8e308';
        
    else
        % Integer types: show byte size and value range
        nbytes = f.ByteSize;
        if nbytes == 1
            sizeStr = '1 byte';
        else
            sizeStr = sprintf('%d bytes', nbytes);
        end
        
        % Determine if signed or unsigned
        isSigned = contains(f.CType, 'int') && ~contains(f.CType, 'uint');
        
        if isSigned
            % Signed: show range
            maxVal = 2^(nbytes*8-1) - 1;
            minVal = -2^(nbytes*8-1);
            if nbytes <= 2
                maskStr = sprintf('%d to %d', minVal, maxVal);
            else
                maskStr = sprintf('±2^%d', nbytes*8-1);
            end
        else
            % Unsigned: show hex range
            maxVal = 2^(nbytes*8) - 1;
            if nbytes == 1
                maskStr = '0x00-0xFF';
            elseif nbytes == 2
                maskStr = '0x0000-0xFFFF';
            elseif nbytes == 4
                maskStr = '0x00000000-0xFFFFFFFF';
            else
                maskStr = sprintf('0-0x%s', repmat('F', 1, nbytes*2));
            end
        end
    end
end

function result = ternary(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
