classdef HeaderParser
% ScapyML.HeaderParser  Parses C header files into ProtocolDef objects.
%
% Supported C constructs:
%   typedef struct Name { ... } Name;
%   typedef struct { ... } Name;
%   typedef union  Name { ... } Name;
%   typedef union  { ... } Name;
%
% Inline anonymous struct/union inside a union body:
%   typedef union {
%       uint16_t raw;
%       struct { uint8_t lo; uint8_t hi; } bytes;
%   } Word16;
%
% Named inline members are stored as nested ProtocolDef children (not flattened).
% Their fields are still named with the parent prefix (bytes_lo, bytes_hi).
% The Codec handles union semantics by encoding all direct children at offset 0.
%
% KEY PARSING RULE:
%   Collect ALL consecutive word tokens in a field declaration.
%   The LAST word is the field name; everything before it is the type.

    methods (Static)

        % ----------------------------------------------------------------
        % Public entry points
        % ----------------------------------------------------------------

        function protos = parseFile(filename, endian)
            if nargin < 2, endian = 'little'; end
            fid = fopen(filename, 'r');
            if fid < 0
                error('ScapyML:HeaderParser:FileNotFound', ...
                    'Cannot open file: %s', filename);
            end
            src = fread(fid, '*char')';
            fclose(fid);
            protos = ScapyML.HeaderParser.parseSource(src, endian);
        end

        function protos = parseSource(src, endian)
            if nargin < 2, endian = 'little'; end
            tokens = ScapyML.HeaderParser.tokenise(src);
            protos  = ScapyML.HeaderParser.parseTokens(tokens, endian);
        end

        % ----------------------------------------------------------------
        % Tokeniser  (character-by-character, no regex)
        % ----------------------------------------------------------------

        function tokens = tokenise(src)
            tokens = {};
            n      = numel(src);
            i      = 1;
            line   = 1;

            while i <= n
                c = src(i);

                if c == newline || c == char(13)
                    line = line + 1; i = i + 1; continue;
                end
                if c == ' ' || c == char(9)
                    i = i + 1; continue;
                end

                % Line comment //
                if i+1 <= n && c == '/' && src(i+1) == '/'
                    txt = ''; i = i + 2;
                    while i <= n && src(i) ~= newline && src(i) ~= char(13)
                        txt = [txt, src(i)]; i = i + 1; %#ok<AGROW>
                    end
                    tokens{end+1} = struct('kind','comment','text',strtrim(txt),'line',line); %#ok<AGROW>
                    continue;
                end

                % Block comment /* ... */
                if i+1 <= n && c == '/' && src(i+1) == '*'
                    txt = ''; i = i + 2;
                    while i+1 <= n && ~(src(i) == '*' && src(i+1) == '/')
                        if src(i) == newline || src(i) == char(13), line = line + 1; end
                        txt = [txt, src(i)]; i = i + 1; %#ok<AGROW>
                    end
                    i = i + 2;
                    tokens{end+1} = struct('kind','comment','text',strtrim(txt),'line',line); %#ok<AGROW>
                    continue;
                end

                % Preprocessor directive — skip whole line
                if c == '#'
                    while i <= n && src(i) ~= newline && src(i) ~= char(13)
                        i = i + 1;
                    end
                    continue;
                end

                % Identifier / keyword
                if ScapyML.HeaderParser.isIdentStart(c)
                    txt = '';
                    while i <= n && ScapyML.HeaderParser.isIdentChar(src(i))
                        txt = [txt, src(i)]; i = i + 1; %#ok<AGROW>
                    end
                    tokens{end+1} = struct('kind','word','text',txt,'line',line); %#ok<AGROW>
                    continue;
                end

                % Number
                if c >= '0' && c <= '9'
                    txt = '';
                    while i <= n && ((src(i) >= '0' && src(i) <= '9') || ...
                                     src(i) == 'x' || src(i) == 'X'   || ...
                                     (src(i) >= 'a' && src(i) <= 'f') || ...
                                     (src(i) >= 'A' && src(i) <= 'F'))
                        txt = [txt, src(i)]; i = i + 1; %#ok<AGROW>
                    end
                    tokens{end+1} = struct('kind','number','text',txt,'line',line); %#ok<AGROW>
                    continue;
                end

                tokens{end+1} = struct('kind','punct','text',c,'line',line); %#ok<AGROW>
                i = i + 1;
            end
        end

        % ----------------------------------------------------------------
        % Top-level parser
        % ----------------------------------------------------------------

        function protos = parseTokens(tokens, endian)
            protos     = {};
            knownTypes = containers.Map('KeyType','char','ValueType','any');

            primitives = { ...
                'uint8_t','int8_t','char','unsigned char','signed char', ...
                'uint16_t','int16_t','short','unsigned short', ...
                'uint32_t','int32_t','int','unsigned int','unsigned','long','unsigned long', ...
                'uint64_t','int64_t','long long','unsigned long long', ...
                'float','double'};
            for k = 1:numel(primitives)
                knownTypes(primitives{k}) = 'primitive';
            end

            pos = 1;
            n   = numel(tokens);

            lastComment = '';
            while pos <= n
                tok = tokens{pos};
                if strcmp(tok.kind,'comment')
                    lastComment = tok.text;
                    pos = pos + 1;
                    continue;
                end

                if strcmp(tok.kind,'word') && strcmp(tok.text,'typedef')
                    % Check if it's typedef enum or typedef struct/union
                    nextPos = pos + 1;
                    while nextPos <= n && strcmp(tokens{nextPos}.kind,'comment')
                        nextPos = nextPos + 1;
                    end
                    
                    if nextPos <= n && strcmp(tokens{nextPos}.text,'enum')
                        % Parse enum
                        [enumDef, pos] = ScapyML.HeaderParser.parseEnum( ...
                            tokens, pos, n, lastComment);
                        if ~isempty(enumDef)
                            % Store in knownTypes so structs that follow can use it
                            knownTypes(enumDef.Name) = enumDef;
                            % Also return it so the caller can register it
                            protos{end+1} = enumDef; %#ok<AGROW>
                        end
                        lastComment = '';
                        continue;
                    else
                        % Parse struct/union
                        [proto, pos, knownTypes] = ScapyML.HeaderParser.parseTypedef( ...
                            tokens, pos+1, n, knownTypes, endian);
                        if ~isempty(proto)
                            protos{end+1} = proto; %#ok<AGROW>
                            knownTypes(proto.Name) = proto;
                        end
                        lastComment = '';
                        continue;
                    end
                end
                pos = pos + 1;
            end
        end

        % ----------------------------------------------------------------
        % Parse one  typedef struct/union { ... } Name;
        % Returns a ProtocolDef with IsUnion set appropriately.
        % ----------------------------------------------------------------

        function [proto, pos, knownTypes] = parseTypedef(tokens, pos, n, knownTypes, endian)
            proto = [];

            % Skip leading comments
            while pos <= n && strcmp(tokens{pos}.kind,'comment'), pos = pos+1; end

            % Must be 'struct' or 'union'
            if pos > n || ~(strcmp(tokens{pos}.text,'struct') || strcmp(tokens{pos}.text,'union'))
                while pos <= n && ~strcmp(tokens{pos}.text,';'), pos = pos+1; end
                pos = pos + 1;
                % knownTypes already passed in, return unchanged
                return;
            end
            isUnion = strcmp(tokens{pos}.text,'union');
            pos = pos + 1;  % consume 'struct' / 'union'

            while pos <= n && strcmp(tokens{pos}.kind,'comment'), pos = pos+1; end

            % Optional tag name (e.g. "struct Foo {")
            tag = '';
            if pos <= n && strcmp(tokens{pos}.kind,'word')
                tag = tokens{pos}.text; pos = pos + 1;
            end

            while pos <= n && strcmp(tokens{pos}.kind,'comment'), pos = pos+1; end

            % Must have '{'
            if pos > n || ~strcmp(tokens{pos}.text,'{')
                while pos <= n && ~strcmp(tokens{pos}.text,';'), pos = pos+1; end
                pos = pos + 1;
                % knownTypes already passed in, return unchanged
                return;
            end
            pos = pos + 1;  % consume '{'

            % Collect field definitions
            proto           = ScapyML.ProtocolDef('_tmp', endian);
            proto.IsUnion   = isUnion;
            lastComment     = '';

            while pos <= n && ~strcmp(tokens{pos}.text,'}')
                tok = tokens{pos};
                if strcmp(tok.kind,'comment')
                    lastComment = tok.text; pos = pos + 1; continue;
                end

                [entries, pos, lastComment] = ScapyML.HeaderParser.parseField( ...
                    tokens, pos, n, knownTypes, endian, lastComment, isUnion);

                for fi = 1:numel(entries)
                    proto = proto.addField(entries{fi});
                end
            end
            pos = pos + 1;  % consume '}'

            while pos <= n && strcmp(tokens{pos}.kind,'comment'), pos = pos+1; end

            % Typedef alias name
            aliasName = '';
            if pos <= n && strcmp(tokens{pos}.kind,'word')
                aliasName = tokens{pos}.text; pos = pos + 1;
            end
            if pos <= n && strcmp(tokens{pos}.text,';'), pos = pos + 1; end

            finalName = aliasName;
            if isempty(finalName), finalName = tag; end
            if isempty(finalName)
                proto = [];
                % knownTypes already passed in, return unchanged
                return;
            end

            proto.Name  = finalName;
            proto.CName = finalName;
            % MATLAB limits struct field names to 63 characters (namelengthmax):
            % shorten over-long nested-field names, keeping them unique.
            proto = ScapyML.HeaderParser.shortenLongFieldNames(proto);
            proto = proto.recompute();
        end

        % ----------------------------------------------------------------
        % shortenLongFieldNames: make every FieldDef name fit namelengthmax
        % (63). Names already short are untouched and keep priority; a name
        % that is too long is shortened with NameShortener, made unique by
        % a numeric suffix if needed, and its original name is kept in
        % FieldDef.FullName. Emits ONE warning per protocol listing examples.
        % ----------------------------------------------------------------
        function proto = shortenLongFieldNames(proto)
            maxLen = 63;
            used = containers.Map('KeyType','char','ValueType','logical');
            used = ScapyML.HeaderParser.collectShortNames(proto, used, maxLen);
            examples = {};
            nChanged = 0;
            [proto, ~, examples, nChanged] = ScapyML.HeaderParser.applyShortNames( ...
                proto, used, maxLen, examples, nChanged);
            if nChanged > 0
                warning('ScapyML:HeaderParser:NameShortened', ...
                    ['%d field name(s) in "%s" exceeded MATLAB''s %d-character limit and were shortened ', ...
                     '(original names are kept in FieldDef.FullName and also work as CSV column headers). ', ...
                     'Example: %s'], nChanged, proto.Name, maxLen, strjoin(examples, '; '));
            end
        end

        function used = collectShortNames(p, used, maxLen)
            for k = 1:numel(p.Fields)
                f = p.Fields{k};
                if isa(f, 'ScapyML.FieldDef')
                    if length(f.Name) <= maxLen, used(f.Name) = true; end
                elseif isa(f, 'ScapyML.ProtocolDef')
                    used = ScapyML.HeaderParser.collectShortNames(f, used, maxLen);
                end
            end
        end

        function [p, used, examples, nChanged] = applyShortNames(p, used, maxLen, examples, nChanged)
            for k = 1:numel(p.Fields)
                f = p.Fields{k};
                if isa(f, 'ScapyML.FieldDef')
                    if length(f.Name) > maxLen
                        longName = f.Name;
                        cand = ScapyML.NameShortener.shorten(longName, maxLen);
                        n = 1;
                        while used.isKey(cand)
                            n = n + 1;
                            suffix = sprintf('_%d', n);
                            cand = [cand(1:min(numel(cand), maxLen - numel(suffix))), suffix];
                        end
                        used(cand) = true;
                        f.FullName = longName;
                        f.Name = cand;
                        p.Fields{k} = f;
                        nChanged = nChanged + 1;
                        if numel(examples) < 2
                            examples{end+1} = sprintf('%s -> %s', longName, cand); %#ok<AGROW>
                        end
                    end
                elseif isa(f, 'ScapyML.ProtocolDef')
                    [f, used, examples, nChanged] = ScapyML.HeaderParser.applyShortNames( ...
                        f, used, maxLen, examples, nChanged);
                    p.Fields{k} = f;
                end
            end
        end

        % ----------------------------------------------------------------
        % Parse one field declaration inside a struct/union body.
        %
        % Returns a cell array of entries, each of which is either:
        %   - a FieldDef  (for primitive fields)
        %   - a ProtocolDef  (for inline struct/union members)
        %
        % Inline struct/union handling:
        %   typedef union {
        %       uint16_t raw;                     -> FieldDef 'raw'
        %       struct { uint8_t lo; uint8_t hi; } bytes;
        %                                         -> ProtocolDef 'bytes' (IsUnion=false)
        %                                            with FieldDefs bytes_lo, bytes_hi
        %   }
        %
        % The ProtocolDef child is stored in the parent's Fields list.
        % Codec handles the union/struct semantics recursively.
        % fieldNames() depth-first traversal yields: raw, bytes_lo, bytes_hi
        % ----------------------------------------------------------------

        function [entries, pos, lastComment] = parseField( ...
                tokens, pos, n, knownTypes, endian, lastComment, parentIsUnion)
            % parentIsUnion (optional): true if the enclosing block is a union.
            % Needed so an anonymous struct inside a union (or an anonymous
            % union inside a struct) keeps its own layout instead of being
            % flattened into the parent with the wrong overlap semantics.
            if nargin < 7, parentIsUnion = []; end

            entries = {};
            if pos > n
                % lastComment already passed in, return unchanged
                return;
            end

            % Collect all consecutive word tokens
            allWords = {};
            while pos <= n && strcmp(tokens{pos}.kind,'word')
                allWords{end+1} = tokens{pos}.text; pos = pos + 1; %#ok<AGROW>
            end

            if isempty(allWords)
                % No words -> skip to next semicolon
                while pos <= n && ~strcmp(tokens{pos}.text,';'), pos = pos+1; end
                if pos <= n, pos = pos + 1; end
                lastComment = '';
                return;
            end

            % -------------------------------------------------------
            % Inline struct/union: first word is 'struct' or 'union'
            % AND the next non-word token is '{'
            % e.g.  "struct { uint8_t a; uint8_t b; } bytes"
            %        "union  { ... } raw"
            % -------------------------------------------------------
            firstWord = allWords{1};
            if (strcmp(firstWord,'struct') || strcmp(firstWord,'union')) && ...
               pos <= n && strcmp(tokens{pos}.text,'{')

                inlineIsUnion = strcmp(firstWord,'union');
                pos = pos + 1;  % consume '{'

                % Parse the inline block body recursively
                inlineProto         = ScapyML.ProtocolDef('_inline', endian);
                inlineProto.IsUnion = inlineIsUnion;
                innerComment        = '';

                while pos <= n && ~strcmp(tokens{pos}.text,'}')
                    tok = tokens{pos};
                    if strcmp(tok.kind,'comment')
                        innerComment = tok.text; pos = pos + 1; continue;
                    end
                    [innerEntries, pos, innerComment] = ScapyML.HeaderParser.parseField( ...
                        tokens, pos, n, knownTypes, endian, innerComment, inlineIsUnion);
                    for fi = 1:numel(innerEntries)
                        inlineProto = inlineProto.addField(innerEntries{fi});
                    end
                end
                pos = pos + 1;  % consume '}'

                % Skip comments, read the member name (may be absent for truly anonymous)
                while pos <= n && strcmp(tokens{pos}.kind,'comment')
                    lastComment = tokens{pos}.text; pos = pos + 1;
                end

                fname = '';
                if pos <= n && strcmp(tokens{pos}.kind,'word')
                    fname = tokens{pos}.text; pos = pos + 1;
                end

                % Array suffix [N]
                arraySize = 1;
                if pos <= n && strcmp(tokens{pos}.text,'[')
                    pos = pos + 1;
                    if pos <= n && strcmp(tokens{pos}.kind,'number')
                        arraySize = str2double(tokens{pos}.text); pos = pos + 1;
                    end
                    if pos <= n && strcmp(tokens{pos}.text,']'), pos = pos + 1; end
                end

                % Comment before and after semicolon
                if pos <= n && strcmp(tokens{pos}.kind,'comment')
                    lastComment = tokens{pos}.text; pos = pos + 1;
                end
                if pos <= n && strcmp(tokens{pos}.text,';'), pos = pos + 1; end
                if pos <= n && strcmp(tokens{pos}.kind,'comment')
                    lastComment = tokens{pos}.text; pos = pos + 1;
                end
                lastComment = '';  % reset (comment was for this entry)

                if isempty(fname) && arraySize == 1 && ~isempty(parentIsUnion) && ...
                        inlineIsUnion ~= parentIsUnion && ~isempty(inlineProto.Fields)
                    % Anonymous block of the OPPOSITE kind to its parent, e.g.
                    %   union { uint8_t raw; struct { uint8_t a:4; uint8_t b:4; }; };
                    % Flattening would give its members the parent's layout
                    % (the struct's bit-fields would all overlap at the start of
                    % the union). Keep it as a nested ProtocolDef instead, with
                    % the member names unchanged (C11 anonymous-member access).
                    firstName = '';
                    for fi = 1:numel(inlineProto.Fields)
                        if isa(inlineProto.Fields{fi}, 'ScapyML.FieldDef')
                            firstName = inlineProto.Fields{fi}.Name; break;
                        end
                    end
                    if isempty(firstName), firstName = 'blk'; end
                    if inlineIsUnion, kindTag = 'union'; else, kindTag = 'struct'; end
                    childName = ScapyML.NameShortener.shorten(sprintf('anon_%s_%s', kindTag, firstName));
                    entries{end+1} = ScapyML.HeaderParser.prefixProto(inlineProto, '', childName, endian);
                elseif isempty(fname)
                    % Truly anonymous (no field name): flatten its fields directly into parent
                    % This is rare but valid C; treat like struct members without prefix.
                    for rep = 1:arraySize
                        fn = ScapyML.HeaderParser.flattenProto(inlineProto, '', rep, arraySize, endian);
                        for fi = 1:numel(fn)
                            entries{end+1} = fn{fi}; %#ok<AGROW>
                        end
                    end
                else
                    % Named inline block: prefix its field names, store as ProtocolDef child.
                    % The ProtocolDef child keeps track of IsUnion so Codec handles ordering.
                    for rep = 1:arraySize
                        if arraySize > 1
                            prefix = sprintf('%s_%d_', fname, rep);
                            childName = sprintf('%s_%d', fname, rep);
                        else
                            prefix    = [fname, '_'];
                            childName = fname;
                        end
                        child = ScapyML.HeaderParser.prefixProto(inlineProto, prefix, childName, endian);
                        entries{end+1} = child; %#ok<AGROW>
                    end
                end
                return;
            end

            % -------------------------------------------------------
            % Normal field: need at least 2 words (type + name)
            % Last word = field name,  preceding words = type string
            % -------------------------------------------------------
            if numel(allWords) < 2
                while pos <= n && ~strcmp(tokens{pos}.text,';'), pos = pos+1; end
                if pos <= n, pos = pos + 1; end
                lastComment = ''; return;
            end

            fname = allWords{end};
            ctype = strjoin(allWords(1:end-1), ' ');

            % Array suffix [N]
            arraySize = 1;
            if pos <= n && strcmp(tokens{pos}.text,'[')
                pos = pos + 1;
                
                % Check for valid array size
                if pos <= n && strcmp(tokens{pos}.kind,'number')
                    arraySize = str2double(tokens{pos}.text);
                    pos = pos + 1;
                else
                    % BUG FIX (KI-NEW-06): previously this only warned and
                    % did NOT advance pos past the invalid token, so the
                    % immediately-following closing-bracket check always
                    % failed too, throwing a confusing, unrelated
                    % "Missing closing bracket" error instead of clearly
                    % explaining the real problem. This is most commonly
                    % hit with a #define'd array size (e.g.
                    % "uint8_t data[MAX_LEN];"), since this hand-rolled
                    % parser does not expand C preprocessor macros. Rather
                    % than silently falling back to a 1-element array
                    % (which could cause hard-to-diagnose downstream data
                    % corruption -- wrong packet size, misaligned fields,
                    % a garbled generated dissector -- with no further
                    % warning), this now raises ONE clear, actionable
                    % error and advances past the bad token.
                    badToken = tokens{pos}.text;
                    pos = pos + 1;
                    error('ScapyML:Parser:InvalidArray', ...
                        ['Array size must be a numeric constant, found: "%s". ' ...
                         'This parser does not expand #define macros -- ' ...
                         'use a literal number (e.g. [16]) instead of a macro name.'], ...
                        badToken);
                end
                
                % Check for closing bracket
                if pos <= n && strcmp(tokens{pos}.text,']')
                    pos = pos + 1;
                else
                    error('ScapyML:Parser:MissingBracket', ...
                        'Missing closing bracket ] for array declaration');
                end
                
                % Check for multi-dimensional arrays (not supported)
                if pos <= n && strcmp(tokens{pos}.text,'[')
                    error('ScapyML:Parser:MultiDimArray', ...
                        'Multi-dimensional arrays not supported. Use 1D array of size %d*%d', ...
                        arraySize, arraySize);
                end
            end

            % Bit-field width : N
            bitSize = 0;
            if pos <= n && strcmp(tokens{pos}.text,':')
                pos = pos + 1;
                if pos <= n && strcmp(tokens{pos}.kind,'number')
                    bitSize = str2double(tokens{pos}.text); pos = pos + 1;
                end
            end

            % Comment before semicolon (rare)
            if pos <= n && strcmp(tokens{pos}.kind,'comment')
                lastComment = tokens{pos}.text; pos = pos + 1;
            end
            % Semicolon
            if pos <= n && strcmp(tokens{pos}.text,';'), pos = pos + 1; end
            % Comment after semicolon (most common inline pattern)
            if pos <= n && strcmp(tokens{pos}.kind,'comment')
                lastComment = tokens{pos}.text; pos = pos + 1;
            end

            descr       = lastComment;
            lastComment = '';

            % Build field entries
            %
            % Type resolution order (fixed v2.3.3 — cross-file references):
            %   1. knownTypes  — structs/enums defined EARLIER IN THIS SAME FILE
            %   2. ProtocolRegistry — structs/enums defined in a PREVIOUSLY
            %      parsed file (e.g. a shared enum in types.h, referenced
            %      from a struct in status.h parsed in a separate
            %      parseFile() call). Without this fallback, ctypeBytes()
            %      silently returns 0 for the unrecognized type name,
            %      producing a 0-length field in the Wireshark dissector.
            %   3. Primitive / genuinely unknown type
            reg = ScapyML.ProtocolRegistry.instance();
            isKnownLocalStruct = knownTypes.isKey(ctype) && isa(knownTypes(ctype),'ScapyML.ProtocolDef');
            isKnownLocalEnum   = knownTypes.isKey(ctype) && isa(knownTypes(ctype),'ScapyML.EnumDef');
            isRegistryStruct   = ~isKnownLocalStruct && ~isKnownLocalEnum && reg.has(ctype);
            isRegistryEnum     = ~isKnownLocalStruct && ~isKnownLocalEnum && ~isRegistryStruct && reg.hasEnum(ctype);

            if isKnownLocalStruct || isRegistryStruct
                % Known struct/union type used as a field — store as ProtocolDef child
                if isKnownLocalStruct
                    nested = knownTypes(ctype);
                else
                    nested = reg.get(ctype);   % resolved from a previously parsed file
                end
                for rep = 1:arraySize
                    if arraySize > 1
                        prefix    = sprintf('%s_%d_', fname, rep);
                        childName = sprintf('%s_%d', fname, rep);
                    else
                        prefix    = [fname, '_'];
                        childName = fname;
                    end
                    child = ScapyML.HeaderParser.prefixProto(nested, prefix, childName, endian);
                    entries{end+1} = child; %#ok<AGROW>
                end
            elseif isKnownLocalEnum || isRegistryEnum
                % Known enum type used as a field.
                % In C, an unscoped enum has the same size as 'int' (4 bytes on all
                % common 32/64-bit platforms).  Using 1 byte was incorrect and caused
                % wrong byte offsets for all fields that follow the enum.
                fd             = ScapyML.FieldDef();
                fd.CName       = fname;
                fd.CType       = ctype;  % Keep original enum type name for dissector lookup
                fd.Endian      = endian;
                fd.Description = descr;
                fd.Name        = ScapyML.HeaderParser.safeFieldName(fname);
                fd.ByteSize    = 4;  % enum == int == 4 bytes (standard C ABI)
                
                % Array handling
                if arraySize > 1
                    fd.IsArray   = true;
                    fd.ArraySize = arraySize;
                end
                
                entries{end+1} = fd; %#ok<AGROW>
            else
                % Primitive (or unknown) type
                fd             = ScapyML.FieldDef();
                fd.CName       = fname;
                fd.CType       = ctype;
                fd.Endian      = endian;
                fd.Description = descr;
                fd.Name        = ScapyML.HeaderParser.safeFieldName(fname);
                
                % Array handling
                if arraySize > 1
                    fd.IsArray   = true;
                    fd.ArraySize = arraySize;
                end

                if bitSize > 0
                    fd.BitSize    = bitSize;
                    fd.IsBitField = true;
                    fd.ByteSize   = ceil(bitSize / 8);
                else
                    fd.ByteSize = ScapyML.FieldDef.ctypeBytes(ctype);
                    if fd.ByteSize == 0
                        % Fixed v2.3.3: previously silent. A 0-byte field
                        % produces buffer(offset, 0) in generated Wireshark
                        % dissectors — visible only as a mysterious
                        % zero-length field with no diagnostic. Most common
                        % cause: ctype refers to a struct/enum defined in a
                        % header that was not yet loaded (or not loaded at
                        % all) when this file was parsed. Load dependency
                        % headers first, or load all related files together
                        % so ProtocolRegistry can resolve cross-file types.
                        warning('ScapyML:HeaderParser:UnresolvedType', ...
                            ['Field "%s" has unrecognized type "%s" — treating ' ...
                             'as 0 bytes. If "%s" is a struct or enum, make sure ' ...
                             'its header is loaded BEFORE this one.'], ...
                            fname, ctype, ctype);
                    end
                end

                entries{end+1} = fd; %#ok<AGROW>
            end
        end

        % ----------------------------------------------------------------
        % prefixProto: create a copy of a ProtocolDef with all FieldDef
        % names prepended with 'prefix', and set the new name to childName.
        % Recurses into nested ProtocolDef children.
        % ----------------------------------------------------------------
        function child = prefixProto(proto, prefix, childName, endian)
            child         = ScapyML.ProtocolDef(childName, endian);
            child.CName   = childName;
            child.IsUnion = proto.IsUnion;

            for k = 1:numel(proto.Fields)
                f = proto.Fields{k};
                if isa(f,'ScapyML.FieldDef')
                    newF        = f;
                    % Build from the ORIGINAL long path name when an inner
                    % level had to shorten its name (see uniquifyNames), so
                    % the final name is shortened once, from the full path.
                    base = f.Name;
                    if ~isempty(f.FullName), base = f.FullName; end
                    newF.Name     = [prefix, base];
                    newF.FullName = '';
                    newF.Endian   = endian;
                    child = child.addField(newF);
                elseif isa(f,'ScapyML.ProtocolDef')
                    % Recurse: nested ProtocolDef inside this one.
                    % The nested block's field names already carry the block's
                    % own member name as prefix (e.g. 'pos_x'), so only the
                    % outer prefix is added here. (Previously the member name
                    % was added twice, giving 'outer_pos_pos_x' and needlessly
                    % long names.)
                    subName     = [prefix, f.Name];
                    subChild    = ScapyML.HeaderParser.prefixProto(f, prefix, subName, endian);
                    child = child.addField(subChild);
                end
            end
            child = child.recompute();
        end

        % ----------------------------------------------------------------
        % flattenProto: extract all FieldDefs from a proto into a flat cell
        % (used for truly anonymous inline blocks with no field name)
        % ----------------------------------------------------------------
        function fields = flattenProto(proto, prefix, rep, arraySize, endian)
            fields = {};
            for k = 1:numel(proto.Fields)
                f = proto.Fields{k};
                if isa(f,'ScapyML.FieldDef')
                    newF = f;
                    if arraySize > 1
                        longName = sprintf('%s%s_%d', prefix, f.Name, rep);
                    else
                        longName = [prefix, f.Name];
                    end
                    % Apply name shortening if needed (MATLAB 63-char limit)
                    newF.Name = ScapyML.NameShortener.shorten(longName);
                    newF.Endian = endian;
                    fields{end+1} = newF; %#ok<AGROW>
                elseif isa(f,'ScapyML.ProtocolDef')
                    subFields = ScapyML.HeaderParser.flattenProto(f, [prefix, f.Name, '_'], rep, 1, endian);
                    fields = [fields, subFields]; %#ok<AGROW>
                end
            end
        end

        % ----------------------------------------------------------------
        % Character classification helpers  (no regex)
        % ----------------------------------------------------------------

        function tf = isIdentStart(c)
            tf = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
        end

        function tf = isIdentChar(c)
            tf = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || ...
                 (c >= '0' && c <= '9') || c == '_';
        end

        function name = safeFieldName(cname)
            name = cname;
            for k = 1:numel(name)
                ch = name(k);
                if ~((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ...
                     (ch >= '0' && ch <= '9') || ch == '_')
                    name(k) = '_';
                end
            end
            if ~isempty(name) && (name(1) >= '0' && name(1) <= '9')
                name = ['f_', name];
            end
        end
        
        % ----------------------------------------------------------------
        % Parse enum definition
        % ----------------------------------------------------------------
        function [enumDef, pos] = parseEnum(tokens, pos, n, lastComment)
            % Parse: typedef enum [TagName] { VALUE1 = 0, VALUE2, ... } TypeName;
            % The optional TagName between 'enum' and '{' is skipped.
            
            enumDef = [];
            
            % Skip 'typedef' and 'enum'
            pos = pos + 2;
            
            % Skip optional tag name (e.g. 'typedef enum EnuName { ... }')
            if pos <= n && strcmp(tokens{pos}.kind, 'word') && ~strcmp(tokens{pos}.text, '{')
                pos = pos + 1;  % skip the tag
            end
            
            % Expect '{'
            if pos > n || ~strcmp(tokens{pos}.text, '{')
                % Malformed — skip to semicolon
                while pos <= n && ~strcmp(tokens{pos}.text, ';')
                    pos = pos + 1;
                end
                if pos <= n, pos = pos + 1; end
                return;
            end
            pos = pos + 1;
            
            % Create enum with temporary name
            enumDef = ScapyML.EnumDef('TempEnum');
            enumDef.Description = lastComment;
            
            currentValue = 0;
            
            % Parse enum values
            while pos <= n
                % Check for end of enum body
                if strcmp(tokens{pos}.text, '}')
                    pos = pos + 1;
                    break;
                end
                
                % Skip non-word tokens (commas already handled below)
                if ~strcmp(tokens{pos}.kind, 'word')
                    pos = pos + 1;
                    continue;
                end
                
                valueName = tokens{pos}.text;
                pos = pos + 1;
                
                % Check for explicit value assignment
                if pos <= n && strcmp(tokens{pos}.text, '=')
                    pos = pos + 1;
                    if pos <= n && strcmp(tokens{pos}.kind, 'number')
                        currentValue = str2double(tokens{pos}.text);
                        pos = pos + 1;
                    end
                end
                
                enumDef = enumDef.addValue(valueName, currentValue);
                currentValue = currentValue + 1;
                
                % Skip trailing comma
                if pos <= n && strcmp(tokens{pos}.text, ',')
                    pos = pos + 1;
                end
            end
            
            % The typedef name follows '}' — may differ from the tag name
            if pos <= n && strcmp(tokens{pos}.kind, 'word')
                enumDef.Name = tokens{pos}.text;
                pos = pos + 1;
            end
            
            % Skip semicolon
            if pos <= n && strcmp(tokens{pos}.text, ';')
                pos = pos + 1;
            end
        end
        
    end
end
