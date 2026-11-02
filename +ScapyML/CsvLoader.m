classdef CsvLoader
% ScapyML.CsvLoader  Read a CSV file and produce a cell-array of Packet objects.
%
% Rules:
%   - Column headers must match protocol field names (extra columns are ignored)
%   - Fields inside nested structs/unions are stored as <member>_<field>
%     (e.g. pos_x). A column may be written as  pos_x,  pos.x,  Pos X  (case
%     and punctuation are ignored)  or just the bare C field name  x  when
%     that name is unique in the protocol.
%   - Missing columns get their protocol default value (0)
%   - Empty cells leave the field at its default
%   - Numeric strings and hex strings (0x...) are supported
%
% Usage:
%   pkts = ScapyML.CsvLoader.load('data.csv', 'MyProtocol');
%   % pkts is a cell array; pkts{1}, pkts{2} ... are Packet objects

    methods (Static)

        function pkts = load(csvFile, protoName)
            % Load CSV and return a cell array of ScapyML.Packet objects.

            if ~isfile(csvFile)
                error('ScapyML:CsvLoader:FileNotFound', ...
                    'CSV file not found: %s', csvFile);
            end

            % Read the file line by line
            fid   = fopen(csvFile,'r');
            lines = {};
            while ~feof(fid)
                ln = fgetl(fid);
                if ischar(ln)
                    lines{end+1} = ln; %#ok<AGROW>
                end
            end
            fclose(fid);

            if isempty(lines)
                pkts = {};
                return;
            end

            % Parse header row
            headers = ScapyML.CsvLoader.splitLine(lines{1});
            headers = strtrim(headers);
            nameMap = ScapyML.CsvLoader.buildNameMap( ...
                ScapyML.ProtocolRegistry.instance().get(protoName));

            % Parse data rows
            pkts = {};
            for row = 2:numel(lines)
                ln = strtrim(lines{row});
                if isempty(ln), continue; end

                cells = ScapyML.CsvLoader.splitLine(ln);

                pkt = ScapyML.Packet(protoName);

                for col = 1:min(numel(headers), numel(cells))
                    fname = strtrim(headers{col});
                    raw   = strtrim(cells{col});
                    resolved = ScapyML.CsvLoader.resolveHeader(fname, nameMap);
                    if ~isempty(resolved), fname = resolved; end

                    if isempty(fname) || isempty(raw)
                        continue;
                    end

                    % Convert to number
                    val = ScapyML.CsvLoader.parseNum(raw);
                    if ~isnan(val)
                        try
                            pkt.set(fname, val);
                        catch
                            % Field not in protocol - silently skip
                        end
                    end
                end

                pkts{end+1} = pkt; %#ok<AGROW>
            end
        end

        % ----------------------------------------------------------------
        % Bulk path (used by ScapyML_fromCSV and the GUI)
        % ----------------------------------------------------------------

        function T = readColumns(csvFile, wanted, proto)
            % Read ONLY the columns that map to the protocol fields in
            % 'wanted' (cellstr). Type detection is identical to
            % readtable(csvFile); unwanted columns are simply not
            % converted/stored, which is the big saving for wide files
            % (e.g. 170 columns x 150k rows).
            %
            % proto (optional): the ProtocolDef. When given, columns of
            % nested structs may use alternative spellings (pos.x, Pos X,
            % or the bare field name x if unique); the returned table's
            % variables are renamed to the real protocol field names.
            opts = detectImportOptions(csvFile);
            hdrs = opts.VariableNames;
            if nargin >= 3 && ~isempty(proto)
                nameMap = ScapyML.CsvLoader.buildNameMap(proto);
            else
                nameMap = [];
            end

            target = repmat({''}, 1, numel(hdrs));
            claimed = {};
            % pass 1: exact field-name matches win
            for i = 1:numel(hdrs)
                if ismember(hdrs{i}, wanted) && ~ismember(hdrs{i}, claimed)
                    target{i} = hdrs{i};
                    claimed{end+1} = hdrs{i}; %#ok<AGROW>
                end
            end
            % pass 2: alternative spellings of nested-struct fields
            if ~isempty(nameMap)
                for i = 1:numel(hdrs)
                    if ~isempty(target{i}), continue; end
                    t = ScapyML.CsvLoader.resolveHeader(hdrs{i}, nameMap);
                    if ~isempty(t) && ismember(t, wanted) && ~ismember(t, claimed)
                        target{i} = t;
                        claimed{end+1} = t; %#ok<AGROW>
                    end
                end
            end

            selIdx = find(~cellfun(@isempty, target));
            opts.SelectedVariableNames = hdrs(selIdx);
            T = readtable(csvFile, opts);
            for k = selIdx(:)'
                j = find(strcmp(T.Properties.VariableNames, hdrs{k}), 1);
                if ~isempty(j) && ~strcmp(hdrs{k}, target{k})
                    T.Properties.VariableNames{j} = target{k};
                end
            end
        end

        function nameMap = buildNameMap(proto)
            % Lookup tables for matching CSV headers to protocol fields.
            %   exact - field name -> field name
            %   full  - normalized field name -> field name   (pos.x == pos_x)
            %   bare  - normalized C field name -> field name ('' if the
            %           bare name occurs in more than one struct)
            nameMap = struct('exact', containers.Map(), ...
                             'full',  containers.Map(), ...
                             'bare',  containers.Map());
            fds = ScapyML.Packet.collectFields(proto.Fields);
            for i = 1:numel(fds)
                fd = fds{i};
                nameMap.exact(fd.Name) = fd.Name;
                kf = ScapyML.CsvLoader.normKey(fd.Name);
                if ~nameMap.full.isKey(kf), nameMap.full(kf) = fd.Name; end
                if ~isempty(fd.CName)
                    kb = ScapyML.CsvLoader.normKey(fd.CName);
                    if nameMap.bare.isKey(kb) && ~strcmp(nameMap.bare(kb), fd.Name)
                        nameMap.bare(kb) = '';          % ambiguous
                    elseif ~nameMap.bare.isKey(kb)
                        nameMap.bare(kb) = fd.Name;
                    end
                end
            end
        end

        function name = resolveHeader(header, nameMap)
            % Map a CSV column header to a protocol field name ('' if none).
            name = '';
            if isempty(header) || isempty(nameMap), return; end
            if nameMap.exact.isKey(header)
                name = nameMap.exact(header); return;
            end
            k = ScapyML.CsvLoader.normKey(header);
            if nameMap.full.isKey(k)
                name = nameMap.full(k); return;
            end
            if nameMap.bare.isKey(k)
                name = nameMap.bare(k);
                if isempty(name)
                    warning('ScapyML:CsvLoader:AmbiguousColumn', ...
                        ['CSV column "%s" matches fields in more than one ', ...
                         'struct and was ignored; use the full name (e.g. pos_%s).'], ...
                        header, header);
                end
            end
        end

        function k = normKey(s)
            % Case/punctuation-insensitive key: "Pos.X", "pos_x" -> "posx"
            k = lower(regexprep(s, '[^A-Za-z0-9]', ''));
        end

        function [pkts, cancelled] = buildPackets(proto, defaultValues, T, converter, progressFcn)
            % Build one Packet per row of table T.
            %   defaultValues - struct of ALL protocol fields at defaults
            %   converter     - ScapyML.ConversionManager
            %   progressFcn   - optional @(i,n) -> true to cancel
            % Conversions are applied once to the raw column (no double scaling).
            if nargin < 5, progressFcn = []; end
            cancelled = false;
            nRows = height(T);
            names = T.Properties.VariableNames;

            % -- extract mapped numeric columns, convert once per column --
            mappedNames = {};
            mappedVecs  = {};
            for j = 1:numel(names)
                fn = names{j};
                if ~isfield(defaultValues, fn), continue; end
                raw = T.(fn);
                if ~isnumeric(raw), continue; end
                if converter.hasConversion(fn)
                    raw = converter.convertVector(fn, raw);
                end
                mappedNames{end+1} = fn;  %#ok<AGROW>
                mappedVecs{end+1}  = raw; %#ok<AGROW>
            end

            % -- template cell row holding every protocol field's default --
            allNames = fieldnames(defaultValues);
            baseCell = struct2cell(defaultValues);          % nAll x 1
            [~, idx] = ismember(mappedNames, allNames);     % positions to override
            nMapped  = numel(mappedNames);

            pkts = cell(1, nRows);
            blockSize = 4096;                               % bounds memory
            updateStep = max(1, floor(nRows/200));
            for b0 = 1:blockSize:nRows
                rows = b0:min(b0+blockSize-1, nRows);
                nb   = numel(rows);
                blk  = cell(nb, nMapped);                   % keeps each column's class
                for k = 1:nMapped
                    blk(:,k) = num2cell(mappedVecs{k}(rows));
                end
                for r = 1:nb
                    i = rows(r);
                    v = baseCell;
                    v(idx) = blk(r,:);
                    pkts{i} = ScapyML.Packet.fromValues(proto, cell2struct(v, allNames, 1));
                    if ~isempty(progressFcn) && mod(i, updateStep) == 0
                        if progressFcn(i, nRows)
                            cancelled = true;
                            pkts = pkts(1:i);
                            return;
                        end
                    end
                end
            end
        end

        % ----------------------------------------------------------------
        % Helpers
        % ----------------------------------------------------------------

        function cells = splitLine(line)
            % Split a CSV line on commas, respecting double-quoted fields.
            cells = {};
            cur   = '';
            inQ   = false;

            for k = 1:numel(line)
                ch = line(k);
                if ch == '"'
                    inQ = ~inQ;
                elseif ch == ',' && ~inQ
                    cells{end+1} = cur; %#ok<AGROW>
                    cur = '';
                else
                    cur = [cur, ch]; %#ok<AGROW>
                end
            end
            cells{end+1} = cur;
        end

        function val = parseNum(s)
            % Parse a numeric string; supports decimal and 0x hex.
            % Returns the value in appropriate numeric type to preserve precision
            % Supports: int8, int16, int32, int64, uint8, uint16, uint32, uint64
            
            s = strtrim(s);
            
            if isempty(s)
                val = NaN;
                return;
            end
            
            % Check for hex notation
            if numel(s) > 2 && s(1) == '0' && (s(2)=='x' || s(2)=='X')
                % Hex value - parse as unsigned
                hexStr = s(3:end);
                
                % Determine size based on number of hex digits
                numDigits = length(hexStr);
                
                if numDigits <= 2
                    % uint8: 0x00 to 0xFF
                    val = uint8(hex2dec(hexStr));
                elseif numDigits <= 4
                    % uint16: 0x0000 to 0xFFFF
                    val = uint16(hex2dec(hexStr));
                elseif numDigits <= 8
                    % uint32: 0x00000000 to 0xFFFFFFFF
                    val = uint32(hex2dec(hexStr));
                else
                    % uint64: 0x0000000000000000 to 0xFFFFFFFFFFFFFFFF
                    % hex2dec maxes out at 2^52, so use sscanf for 64-bit
                    val = uint64(sscanf(hexStr, '%lx'));
                end
                
            else
                % Decimal value - preserve as double initially
                % MATLAB's str2double handles scientific notation and negatives
                val = str2double(s);
                
                % Don't convert to integer here - let Packet.set() handle it
                % This preserves negative values and allows proper range checking
            end
        end

    end
end
