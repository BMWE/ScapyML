function pkts = ScapyML_fromCSV(protoName, csvFile, defaultsFile, conversionFile)
%SCAPYML_FROMCSV Bulk-create packets from a CSV file, with optional
%defaults and conversions applied.
%
%   pkts = ScapyML_fromCSV(protoName, csvFile)
%   pkts = ScapyML_fromCSV(protoName, csvFile, defaultsFile)
%   pkts = ScapyML_fromCSV(protoName, csvFile, defaultsFile, conversionFile)
%
% This function implements the CLI 'fromCSV'/'fromcsv' command and the
% GUI's "Load from CSV" (with a defaults file) option. It was previously
% missing from the delivered package entirely (see STR.md Known Issue
% KI-NEW-01) -- calling ScapyML('fromCSV', ...) raised "Undefined
% function" once the duplicate switch-case label shadowing it in
% ScapyML.m was also fixed.
%
% Behaviour is modeled directly on ScapyML_GUI.m's own proven, working
% vectorized CSV loader (used when no defaults file is selected), with
% defaults-file support added on top:
%   1. A base set of field values is built by taking the protocol's own
%      declared defaults, then overlaying any values from defaultsFile
%      (if given) via DefaultsManager.apply.
%   2. Each CSV column that maps to a protocol field is extracted once as
%      a raw column vector; if a conversion is defined for that field,
%      the physical->wire conversion is applied ONCE to that raw column
%      (never to a previously-converted value), matching the "no
%      double-scaling" guard documented in the GUI's own loader.
%   3. One packet per CSV row is built via Packet.fromValuesStruct,
%      starting from the (defaults-applied) base values and overriding
%      with that row's converted CSV values.
%
%   Example:
%       pkts = ScapyML_fromCSV('SensorMsg', 'data.csv', ...
%                               'defaults.txt', 'conversions.txt');

    narginchk(2, 4);
    if nargin < 3
        defaultsFile = '';
    end
    if nargin < 4
        conversionFile = '';
    end

    if ~isfile(csvFile)
        error('ScapyML:fromCSV:FileNotFound', 'CSV file not found: %s', csvFile);
    end

    proto = ScapyML.ProtocolRegistry.instance().get(protoName);

    % ---- Step 1: build the base (defaults-applied) field-value struct ----
    basePkt = ScapyML.Packet(protoName);
    if ~isempty(defaultsFile)
        if isfile(defaultsFile)
            basePkt = ScapyML.DefaultsManager.apply(basePkt, defaultsFile);
        else
            warning('ScapyML:fromCSV:DefaultsFileNotFound', ...
                'Defaults file not found: %s -- proceeding without defaults', defaultsFile);
        end
    end
    % Packet.Values is a private property (not accessible from outside
    % the class) -- extract the base field values via the public
    % fieldNames()/get() API instead.
    baseNames = basePkt.fieldNames();
    defaultValues = struct();
    for i = 1:numel(baseNames)
        defaultValues.(baseNames{i}) = basePkt.get(baseNames{i});
    end

    % ---- Step 2: load conversions (if any) ----
    if ~isempty(conversionFile) && isfile(conversionFile)
        converter = ScapyML.ConversionManager(conversionFile);
    else
        converter = ScapyML.ConversionManager();  % empty -> pass-through
    end

    % ---- Step 3: bulk-read ONLY the protocol-mapped CSV columns ----
    % (reading all 170+ columns and building structs per row was the
    % bottleneck for large files; see CsvLoader.readColumns/buildPackets)
    % Conversions are applied to raw (physical) values once per column.
    T    = ScapyML.CsvLoader.readColumns(csvFile, baseNames, proto);

    % ---- Step 4: build one packet per row (block-vectorized) ----
    pkts = ScapyML.CsvLoader.buildPackets(proto, defaultValues, T, converter);
end
