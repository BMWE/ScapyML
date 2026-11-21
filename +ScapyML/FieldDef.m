classdef FieldDef
% ScapyML.FieldDef  Describes one field within a protocol structure.
%
% Properties:
%   Name       - MATLAB-safe field name
%   CName      - Original C name
%   BitSize    - Width in bits  (0 means use CType to determine width)
%   CType      - Original C type string (e.g. 'uint8_t', 'uint32_t')
%   ByteSize   - Derived byte width (only meaningful when BitSize is a
%                multiple of 8, otherwise the parent struct manages packing)
%   IsBitField - true when declared with ': N' bit-field syntax
%   IsStruct   - true when the field type is itself a registered struct
%   StructType - name of nested struct (valid when IsStruct==true)
%   DefaultVal - default numeric value
%   Description- comment extracted from the header
%   Endian     - 'big' or 'little'  (inherited from parent, overridable)

    properties
        Name        (1,:) char = ''
        CName       (1,:) char = ''
        BitSize     (1,1) double = 0
        CType       (1,:) char = ''
        ByteSize    (1,1) double = 0
        IsBitField  (1,1) logical = false
        IsStruct    (1,1) logical = false
        StructType  (1,:) char = ''
        DefaultVal  (1,1) double = 0
        Description (1,:) char = ''
        Endian      (1,:) char = 'little'
        IsArray     (1,1) logical = false
        ArraySize   (1,1) double = 0
        FullName    (1,:) char = ''   % original (unshortened) path name when Name had to be shortened to 63 chars
    end

    methods
        function n = displayName(obj)
            % Name to SHOW to people: the full (unshortened) path name when
            % Name had to be shortened to fit MATLAB's 63-char limit.
            % Name itself stays the short key used for all data processing.
            if ~isempty(obj.FullName)
                n = obj.FullName;
            else
                n = obj.Name;
            end
        end

        function obj = FieldDef(name, cname, ctype, bitsize, endian)
            if nargin == 0, return; end
            obj.Name   = name;
            obj.CName  = cname;
            obj.CType  = ctype;
            if nargin >= 4
                obj.BitSize = bitsize;
                obj.IsBitField = (bitsize > 0);
            end
            if nargin >= 5
                obj.Endian = endian;
            end
            obj.ByteSize = ScapyML.FieldDef.ctypeBytes(ctype);
            if obj.IsBitField && obj.ByteSize == 0
                obj.ByteSize = ceil(bitsize / 8);
            end
        end
    end

    methods (Static)
        function n = ctypeBytes(ctype)
            % Return byte-width of a primitive C type.
            % Returns 0 for unknown / struct types.
            map = containers.Map( ...
                {'uint8_t','int8_t','char','unsigned char','signed char', ...
                 'uint16_t','int16_t','short','unsigned short', ...
                 'uint32_t','int32_t','int','unsigned int','unsigned','long','unsigned long', ...
                 'uint64_t','int64_t','long long','unsigned long long', ...
                 'float','double'}, ...
                {1,1,1,1,1, 2,2,2,2, 4,4,4,4,4,4,4, 8,8,8,8, 4,8});
            t = strtrim(ctype);
            if map.isKey(t)
                n = map(t);
            else
                n = 0;   % unknown / nested struct
            end
        end
    end
end
