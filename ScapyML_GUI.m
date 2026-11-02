function ScapyML_GUI()
    % ScapyML_GUI - Graphical User Interface for ScapyML Protocol Framework
    %
    % Features:
    %   - Load and parse C header files (single or multiple)
    %   - Automatic dependency resolution
    %   - View protocol information
    %   - Create and manage packets
    %   - Load data from CSV
    %   - Create/edit defaults files
    %   - Send packets via UDP
    %   - Generate Wireshark dissectors
    %   - View packet hex dumps
    
    % Create main figure
    fig = uifigure('Name', 'ScapyML Protocol Framework', ...
        'Position', [100 100 1200 700], ...
        'Color', [0.94 0.94 0.94]);
    
    % Create grid layout
    grid = uigridlayout(fig, [1 2]);
    grid.ColumnWidth = {'1.2x', '2x'};
    
    % Left panel - Controls
    leftPanel = uipanel(grid, 'Title', 'Controls', 'FontWeight', 'bold');
    leftGrid = uigridlayout(leftPanel, [26 1]);  % 25 buttons + 1 flexible spacer
    % Fixed heights for buttons (25px), flexible for spacer ('1x')
    leftGrid.RowHeight = {25, 25, 25, 25, 25, ...  % Section 1: Load Headers (5 rows)
                          25, 25, 25, 25, 25, ...  % Section 2: Protocol Info (5 rows)
                          25, 25, 25, 25, 25, ...  % Section 3: Packet (5 rows)
                          25, 25, 25, 25, 25, 25, 25, ...  % Section 4: Data (7 rows - added Save/Load MAT)
                          25, 25, 25, 25, ...      % Section 5: Actions (4 rows)
                          '1x'};                   % Flexible spacer at bottom
    leftGrid.Padding = [10 10 10 10];
    leftGrid.RowSpacing = 5;
    % Show a vertical scroll bar when the window is too small (or not
    % maximized) to show all the buttons.
    leftGrid.Scrollable = 'on';
    
    % Right panel - Output/View
    rightPanel = uipanel(grid, 'Title', 'Output', 'FontWeight', 'bold');
    rightGrid = uigridlayout(rightPanel, [1 1]);
    rightGrid.Padding = [5 5 5 5];
    
    % Output text area
    outputText = uitextarea(rightGrid, ...
        'Value', 'Welcome to ScapyML GUI!', ...
        'Editable', 'off', ...
        'FontName', 'Courier New', ...
        'FontSize', 14);
    
    % State variables
    state = struct();
    state.loadedProtocols = {};
    state.selectedProtocol = '';
    state.currentPacket = [];
    state.packets = {};
    state.defaultsFile = '';
    state.csvFile = '';
    state.conversionFile = '';  % Physical-to-wire conversion definitions
    state.checksumFile = '';    % Checksum calculation formulas
    
    % --- Section 1: Load Headers ---
    uilabel(leftGrid, 'Text', '═══ LOAD HEADERS ═══', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center');
    
    btnLoadSingle = uibutton(leftGrid, 'Text', '📁 Load Single Header', ...
        'ButtonPushedFcn', @(~,~) loadSingleHeader());
    
    btnLoadMultiple = uibutton(leftGrid, 'Text', '📂 Load Multiple Headers', ...
        'ButtonPushedFcn', @(~,~) loadMultipleHeaders());
    
    cbAutoResolve = uicheckbox(leftGrid, 'Text', 'Auto-resolve dependencies', ...
        'Value', true);
    
    ddEndian = uidropdown(leftGrid, ...
        'Items', {'big-endian (Motorola)', 'little-endian (Intel)'}, ...
        'ItemsData', {'big', 'little'}, ...
        'Value', 'big');
    
    % --- Section 2: Protocol Info ---
    uilabel(leftGrid, 'Text', '═══ PROTOCOL INFO ═══', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center');
    
    btnListProtocols = uibutton(leftGrid, 'Text', '📋 List Protocols', ...
        'ButtonPushedFcn', @(~,~) listProtocols());
    
    ddProtocol = uidropdown(leftGrid, ...
        'Items', {'(Select Protocol)'}, ...
        'Value', '(Select Protocol)', ...
        'ValueChangedFcn', @(src,~) protocolSelected(src.Value));
    
    btnShowInfo = uibutton(leftGrid, 'Text', 'ℹ️ Show Protocol Info', ...
        'ButtonPushedFcn', @(~,~) showProtocolInfo(), ...
        'Enable', 'off');
    
    btnClearProtocols = uibutton(leftGrid, 'Text', '🗑️ Clear Protocols', ...
        'ButtonPushedFcn', @(~,~) clearProtocols());
    
    % --- Section 3: Packet Management ---
    uilabel(leftGrid, 'Text', '═══ PACKET ═══', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center');
    
    btnCreatePacket = uibutton(leftGrid, 'Text', '➕ Create Packet', ...
        'ButtonPushedFcn', @(~,~) createPacket(), ...
        'Enable', 'off');
    
    btnEditPacket = uibutton(leftGrid, 'Text', '✏️ Edit Packet Fields', ...
        'ButtonPushedFcn', @(~,~) editPacket(), ...
        'Enable', 'off');
    
    btnShowPacket = uibutton(leftGrid, 'Text', '👁️ Show Packet', ...
        'ButtonPushedFcn', @(~,~) showPacket(), ...
        'Enable', 'off');
    
    btnHexDump = uibutton(leftGrid, 'Text', '🔍 Hex Dump', ...
        'ButtonPushedFcn', @(~,~) hexDump(), ...
        'Enable', 'off');
    
    % --- Section 4: CSV & Defaults ---
    uilabel(leftGrid, 'Text', '═══ DATA ═══', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center');
    
    btnDefaults = uibutton(leftGrid, 'Text', '📝 Create Defaults File', ...
        'ButtonPushedFcn', @(~,~) createDefaults(), ...
        'Enable', 'off');
    
    btnConversions = uibutton(leftGrid, 'Text', '🔄 Load Conversion File', ...
        'ButtonPushedFcn', @(~,~) loadConversions(), ...
        'Enable', 'off');
    
    btnChecksums = uibutton(leftGrid, 'Text', '🔢 Load Checksums File', ...
        'ButtonPushedFcn', @(~,~) loadChecksums(), ...
        'Enable', 'off');
    
    btnLoadCSV = uibutton(leftGrid, 'Text', '📊 Load from CSV', ...
        'ButtonPushedFcn', @(~,~) loadFromCSV(), ...
        'Enable', 'off');
    
    btnSaveMAT = uibutton(leftGrid, 'Text', '💾 Save to MAT', ...
        'ButtonPushedFcn', @(~,~) saveToMAT(), ...
        'Enable', 'off');
    
    btnLoadMAT = uibutton(leftGrid, 'Text', '📂 Load from MAT', ...
        'ButtonPushedFcn', @(~,~) loadFromMAT(), ...
        'Enable', 'off');
    
    % --- Section 5: Actions ---
    uilabel(leftGrid, 'Text', '═══ ACTIONS ═══', ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center');
    
    btnSend = uibutton(leftGrid, 'Text', '📡 Send Packet(s)', ...
        'ButtonPushedFcn', @(~,~) sendPackets(), ...
        'Enable', 'off');
    
    btnWireshark = uibutton(leftGrid, 'Text', '🦈 Create Wireshark Dissector', ...
        'ButtonPushedFcn', @(~,~) generateWireshark(), ...
        'Enable', 'off');
    
    btnClear = uibutton(leftGrid, 'Text', '🗑️ Clear Output', ...
        'ButtonPushedFcn', @(~,~) clearOutput());
    
    % Initialize
    appendOutput('ScapyML GUI Ready!');
    appendOutput('1. Load header file(s) to begin');
    appendOutput('2. Select a protocol');
    appendOutput('3. Create packets and send');
    
    %% Helper Functions
    
    function appendOutput(text)
        current = outputText.Value;
        if iscell(current)
            current = strjoin(current, newline);
        end
        outputText.Value = [current newline text];
        scroll(outputText, 'bottom');
    end
    
    function clearOutput()
        outputText.Value = '';
    end
    
    function loadSingleHeader()
        [file, path] = uigetfile({'*.h', 'C Header Files (*.h)'}, ...
            'Select Header File');
        if file == 0
            return;
        end
        
        fullPath = fullfile(path, file);
        endian = getEndian();
        
        try
            clearOutput();
            appendOutput(sprintf('Loading: %s', file));
            ScapyML('load', fullPath, endian);
            state.loadedProtocols = ScapyML('list');
            updateProtocolList();
            appendOutput('✓ Header loaded successfully');
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function loadMultipleHeaders()
        [files, path] = uigetfile({'*.h', 'C Header Files (*.h)'}, ...
            'Select Header Files', 'MultiSelect', 'on');
        if isequal(files, 0)
            return;
        end
        
        if ~iscell(files)
            files = {files};
        end
        
        fullPaths = cellfun(@(f) fullfile(path, f), files, 'UniformOutput', false);
        endian = getEndian();
        autoResolve = cbAutoResolve.Value;
        
        try
            clearOutput();
            appendOutput(sprintf('Loading %d files...', numel(files)));
            for i = 1:numel(files)
                appendOutput(sprintf('  - %s', files{i}));
            end
            
            if autoResolve && numel(files) > 1
                ScapyML('load', fullPaths, endian, 'auto');
            else
                ScapyML('load', fullPaths, endian);
            end
            
            state.loadedProtocols = ScapyML('list');
            updateProtocolList();
            appendOutput('✓ All headers loaded successfully');
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function endian = getEndian()
        % Get endian value from dropdown (uses ItemsData)
        endian = ddEndian.Value;
    end
    
    function updateProtocolList()
        if isempty(state.loadedProtocols)
            ddProtocol.Items = {'(No Protocols Loaded)'};
            ddProtocol.Value = '(No Protocols Loaded)';
        else
            ddProtocol.Items = ['(Select Protocol)', state.loadedProtocols];
            ddProtocol.Value = '(Select Protocol)';
            state.selectedProtocol = '';
        end
    end
    
    function listProtocols()
        clearOutput();
        if isempty(state.loadedProtocols)
            appendOutput('No protocols loaded');
            return;
        end
        
        appendOutput('═══ LOADED PROTOCOLS ═══');
        for i = 1:numel(state.loadedProtocols)
            appendOutput(sprintf('%d. %s', i, state.loadedProtocols{i}));
        end
    end
    
    function protocolSelected(protoName)
        if startsWith(protoName, '(')
            return;
        end
        
        state.selectedProtocol = protoName;
        btnShowInfo.Enable = 'on';
        btnCreatePacket.Enable = 'on';
        btnDefaults.Enable = 'on';
        btnConversions.Enable = 'on';
        btnChecksums.Enable = 'on';
        btnLoadCSV.Enable = 'on';
        btnLoadMAT.Enable = 'on';
        btnWireshark.Enable = 'on';
    end
    
    function showProtocolInfo()
        clearOutput();
        
        % Capture ScapyML output
        appendOutput(sprintf('═══ PROTOCOL INFO: %s ═══', state.selectedProtocol));
        
        try
            % Get protocol
            reg = ScapyML.ProtocolRegistry.instance();
            proto = reg.get(state.selectedProtocol);
            
            appendOutput(sprintf('Total Size: %d bytes', proto.totalBytes()));
            appendOutput(sprintf('Endian: %s', proto.Endian));
            appendOutput(sprintf('Type: %s', ternary(proto.IsUnion, 'UNION', 'STRUCT')));
            appendOutput('');
            
            % Get field offsets using accurate calculation
            offsets = proto.getFieldOffsets();
            
            appendOutput('Field Details:');
            appendOutput(sprintf('%-4s %-30s %-12s %-10s %s', 'No.', 'Name', 'Type', 'Byte Loc', 'Details'));
            appendOutput(repmat('-', 1, 85));
            
            % Display each field with accurate offsets
            for i = 1:numel(offsets)
                info = offsets{i};
                
                % Build details string
                details = '';
                if info.isArray
                    details = sprintf('[%d]', info.arraySize);
                end
                if info.isBitField
                    % Bit-field - show bit offset within byte and bit size
                    details = sprintf('%s bits:%d/%d', details, info.bitOffset, info.bitSize);
                end
                
                appendOutput(sprintf('%-4d %-30s %-12s %-10d %s', ...
                    i, info.name, info.type, info.byteOffset, details));
            end
            
            appendOutput('');
            appendOutput(sprintf('✓ Displayed all %d fields', numel(offsets)));
        catch ME
            appendOutput(sprintf('Error: %s', ME.message));
        end
    end
    
    function createPacket()
        clearOutput();
        try
            state.currentPacket = ScapyML.Packet(state.selectedProtocol);
            appendOutput(sprintf('✓ Created packet: %s', state.selectedProtocol));
            appendOutput('Use "Edit Packet Fields" to set values');
            
            % Store in packets array for MAT file save
            state.packets = {state.currentPacket};
            
            btnEditPacket.Enable = 'on';
            btnShowPacket.Enable = 'on';
            btnHexDump.Enable = 'on';
            btnSend.Enable = 'on';
            btnSaveMAT.Enable = 'on';
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function editPacket()
        if isempty(state.currentPacket)
            appendOutput('No packet created yet');
            return;
        end
        
        % Get field names from packet
        fieldNames = state.currentPacket.fieldNames();
        
        % Create field editor dialog with scrollable panel
        editDlg = uifigure('Name', 'Edit Packet Fields', 'Position', [200 200 700 550]);
        mainGrid = uigridlayout(editDlg, [3 1]);
        mainGrid.RowHeight = {40, '1x', 50};
        
        % Title
        uilabel(mainGrid, 'Text', sprintf('Editing %d fields (scroll below if needed)', numel(fieldNames)), ...
            'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'center', ...
            'FontColor', [0 0.4 0.7]);
        
        % Scrollable panel - must use absolute positioning inside, not grid!
        scrollPanel = uipanel(mainGrid, ...
            'Scrollable', 'on', ...
            'BorderType', 'line', ...
            'BorderWidth', 2, ...
            'BackgroundColor', [0.98 0.98 1.0]);
        
        fieldEdits = {};
        rowHeight = 35;
        yPos = numel(fieldNames) * rowHeight;  % Start from top
        
        % Create field editors with absolute positioning
        for i = 1:numel(fieldNames)
            fname = fieldNames{i};
            
            % Calculate position for this row (from top down)
            currentY = yPos - (i * rowHeight);
            
            % Label
            uilabel(scrollPanel, ...
                'Text', fname, ...
                'FontWeight', 'bold', ...
                'Position', [10, currentY, 200, 25]);
            
            % Edit field - use get() method
            currentVal = state.currentPacket.get(fname);
            if isnumeric(currentVal) && numel(currentVal) > 1
                % Array field
                valStr = sprintf('%g ', currentVal);
                fieldEdits{i} = uieditfield(scrollPanel, 'text', ...
                    'Value', valStr, ...
                    'Position', [220, currentY, 450, 25]);
            else
                fieldEdits{i} = uieditfield(scrollPanel, 'text', ...
                    'Value', num2str(currentVal), ...
                    'Position', [220, currentY, 450, 25]);
            end
        end
        
        % Buttons at bottom
        btnGrid = uigridlayout(mainGrid, [1 2]);
        btnGrid.ColumnWidth = {'1x', '1x'};
        
        btnApply = uibutton(btnGrid, 'Text', 'Apply', ...
            'ButtonPushedFcn', @(~,~) applyFieldEdits());
        
        btnCancel = uibutton(btnGrid, 'Text', 'Cancel', ...
            'ButtonPushedFcn', @(~,~) close(editDlg));
        
        function applyFieldEdits()
            for j = 1:numel(fieldNames)
                fname = fieldNames{j};
                valStr = fieldEdits{j}.Value;
                
                try
                    % Parse value safely (no code execution)
                    if contains(valStr, ' ') || contains(valStr, ',')
                        % Array - parse safely
                        valStr = strrep(valStr, ',', ' ');  % Normalize separators
                        vals = sscanf(valStr, '%f');  % Safe parsing
                        if isempty(vals)
                            error('Invalid array format');
                        end
                        state.currentPacket.set(fname, vals');
                    else
                        % Single value
                        val = str2double(valStr);
                        if isnan(val) && ~strcmp(valStr, 'NaN')
                            error('Invalid numeric value');
                        end
                        state.currentPacket.set(fname, val);
                    end
                catch ME
                    appendOutput(sprintf('Error setting %s: %s', fname, ME.message));
                    % Don't close dialog on error - let user fix it
                end
            end
            appendOutput('✓ Packet fields updated');
            close(editDlg);
        end
    end
    
    function showPacket()
        if isempty(state.currentPacket)
            appendOutput('No packet created yet');
            return;
        end
        
        clearOutput();
        appendOutput('═══ PACKET CONTENTS ═══');
        appendOutput(sprintf('Protocol: %s', state.selectedProtocol));
        appendOutput('');
        
        try
            % Get field names from packet
            fieldNames = state.currentPacket.fieldNames();
            
            % Display each field
            for i = 1:numel(fieldNames)
                fname = fieldNames{i};
                val = state.currentPacket.get(fname);
                
                if isnumeric(val) && numel(val) > 1
                    % Array
                    if numel(val) <= 8
                        valStr = sprintf('[%s]', sprintf('%g ', val));
                    else
                        valStr = sprintf('[%g %g %g ... %d elements]', val(1), val(2), val(3), numel(val));
                    end
                else
                    valStr = num2str(val);
                end
                
                appendOutput(sprintf('  %-30s = %s', fname, valStr));
            end
            
            appendOutput('');
            appendOutput(sprintf('✓ Displayed %d fields', numel(fieldNames)));
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function hexDump()
        if isempty(state.currentPacket)
            appendOutput('No packet created yet');
            return;
        end
        
        clearOutput();
        try
            bytes = state.currentPacket.build();
            appendOutput(sprintf('═══ HEX DUMP (%d bytes) ═══', numel(bytes)));
            
            % Display in rows of 16 bytes
            for i = 1:16:numel(bytes)
                endIdx = min(i+15, numel(bytes));
                hexStr = sprintf('%02X ', bytes(i:endIdx));
                appendOutput(sprintf('%04X: %s', i-1, hexStr));
            end
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function createDefaults()
        [file, path] = uiputfile('*.txt', 'Save Defaults File', ...
            sprintf('%s_defaults.txt', state.selectedProtocol));
        if file == 0
            return;
        end
        
        fullPath = fullfile(path, file);
        
        try
            clearOutput();
            ScapyML('defaults', state.selectedProtocol, fullPath);
            state.defaultsFile = fullPath;
            appendOutput(sprintf('✓ Defaults file created: %s', file));
            appendOutput('Edit this file to set default values');
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function loadConversions()
        [file, path] = uigetfile({'*.txt;*.m', 'Conversion Files (*.txt, *.m)'; ...
                                   '*.txt', 'Text Files (*.txt)'; ...
                                   '*.m', 'MATLAB Files (*.m)'}, ...
            'Select Conversion File');
        if file == 0
            return;
        end
        
        fullPath = fullfile(path, file);
        
        try
            clearOutput();
            % Validate conversion file
            cm = ScapyML.ConversionManager(fullPath);
            state.conversionFile = fullPath;
            appendOutput(sprintf('✓ Loaded conversion file: %s', file));
            appendOutput(sprintf('  %d conversion(s) defined', cm.conversionCount()));
            
            % List conversions
            if cm.conversionCount() > 0
                convNames = cm.listConversions();
                appendOutput('  Fields with conversions:');
                for i = 1:min(10, numel(convNames))
                    appendOutput(sprintf('    - %s', convNames{i}));
                end
                if numel(convNames) > 10
                    appendOutput(sprintf('    ... and %d more', numel(convNames) - 10));
                end
            end
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
        end
    end
    
    function loadChecksums()
        % Load checksum calculation formulas
        [file, path] = uigetfile({'*.txt', 'Text Files (*.txt)'; '*.*', 'All Files'}, ...
            'Select Checksums File');
        if file == 0
            return;
        end
        
        fullPath = fullfile(path, file);
        
        try
            clearOutput();
            % Validate checksum file by trying to load it
            cm = ScapyML.ChecksumManager(fullPath);
            state.checksumFile = fullPath;
            appendOutput(sprintf('✓ Loaded checksums file: %s', file));
            
            % Count checksum formulas using public method
            checksumCount = cm.checksumCount();
            appendOutput(sprintf('  %d checksum formula(s) defined', checksumCount));
            
            % List checksum fields using public method
            if checksumCount > 0
                appendOutput('  Checksum fields:');
                fieldNames = cm.listChecksums();
                for i = 1:min(10, numel(fieldNames))
                    appendOutput(sprintf('    - %s', fieldNames{i}));
                end
                if numel(fieldNames) > 10
                    appendOutput(sprintf('    ... and %d more', numel(fieldNames) - 10));
                end
            end
        catch ME
            appendOutput(sprintf('✗ Error loading checksums: %s', ME.message));
            state.checksumFile = '';
        end
    end
    
    function saveToMAT()
        % Save current packets to MAT file
        if isempty(state.packets)
            uialert(fig, 'No packets to save. Load from CSV first.', 'No Packets');
            return;
        end
        
        [file, path] = uiputfile({'*.mat', 'MAT Files (*.mat)'}, ...
            'Save Packets as MAT File', 'packets.mat');
        if file == 0
            return;
        end
        
        fullPath = fullfile(path, file);
        
        try
            clearOutput();
            
            % Prepare data structure
            packetData = struct();
            packetData.protocolName = state.selectedProtocol;
            packetData.packetCount = numel(state.packets);
            packetData.createdDate = datestr(now);
            packetData.scapymlVersion = 'v2.3.1';
            
            % Store packet data
            packetData.packets = state.packets;
            
            % Store configuration files used (optional metadata)
            if ~isempty(state.defaultsFile)
                packetData.defaultsFile = state.defaultsFile;
            end
            if ~isempty(state.conversionFile)
                packetData.conversionFile = state.conversionFile;
            end
            if ~isempty(state.csvFile)
                packetData.sourceCSV = state.csvFile;
            end
            
            % Save to MAT file
            save(fullPath, 'packetData', '-v7.3');
            
            appendOutput(sprintf('✓ Saved %d packets to: %s', numel(state.packets), file));
            appendOutput(sprintf('  Protocol: %s', state.selectedProtocol));
            appendOutput(sprintf('  File size: %.1f KB', dir(fullPath).bytes / 1024));
            
        catch ME
            appendOutput(sprintf('✗ Error saving MAT file: %s', ME.message));
        end
    end
    
    function loadFromMAT()
        % Load packets from MAT file
        if isempty(state.selectedProtocol) || strcmp(state.selectedProtocol, '(Select Protocol)')
            uialert(fig, 'Please select a protocol first', 'No Protocol Selected');
            return;
        end
        
        [file, path] = uigetfile({'*.mat', 'MAT Files (*.mat)'; '*.*', 'All Files'}, ...
            'Select MAT File');
        if file == 0
            return;
        end
        
        fullPath = fullfile(path, file);
        
        try
            clearOutput();
            appendOutput(sprintf('Loading MAT file: %s', file));
            
            % Load MAT file
            data = load(fullPath);
            
            % Validate structure
            if ~isfield(data, 'packetData')
                error('Invalid MAT file: missing packetData structure');
            end
            
            packetData = data.packetData;
            
            % Validate required fields
            if ~isfield(packetData, 'packets') || ~isfield(packetData, 'protocolName')
                error('Invalid MAT file: missing required fields');
            end
            
            % Check protocol compatibility
            if ~strcmp(packetData.protocolName, state.selectedProtocol)
                answer = uiconfirm(fig, ...
                    sprintf('MAT file protocol (%s) differs from selected protocol (%s). Load anyway?', ...
                    packetData.protocolName, state.selectedProtocol), ...
                    'Protocol Mismatch', ...
                    'Options', {'Yes', 'No'}, ...
                    'DefaultOption', 'No', ...
                    'Icon', 'warning');
                
                if strcmp(answer, 'No')
                    appendOutput('✗ Load cancelled - protocol mismatch');
                    return;
                end
            end
            
            % Load packets
            state.packets = packetData.packets;
            
            % Display information
            appendOutput(sprintf('✓ Loaded %d packets from MAT file', numel(state.packets)));
            appendOutput(sprintf('  Protocol: %s', packetData.protocolName));
            
            if isfield(packetData, 'createdDate')
                appendOutput(sprintf('  Created: %s', packetData.createdDate));
            end
            
            if isfield(packetData, 'scapymlVersion')
                appendOutput(sprintf('  Version: %s', packetData.scapymlVersion));
            end
            
            if isfield(packetData, 'sourceCSV')
                appendOutput(sprintf('  Original CSV: %s', packetData.sourceCSV));
            end
            
            % Enable send and save buttons
            btnSend.Enable = 'on';
            btnSaveMAT.Enable = 'on';
            
        catch ME
            appendOutput(sprintf('✗ Error loading MAT file: %s', ME.message));
            appendOutput('  Make sure the file was created by ScapyML saveToMAT()');
        end
    end
    
    function loadFromCSV()
        % Check if protocol is selected
        if isempty(state.selectedProtocol) || strcmp(state.selectedProtocol, '(Select Protocol)')
            uialert(fig, 'Please select a protocol first', 'No Protocol Selected');
            return;
        end
        
        [file, path] = uigetfile({'*.csv', 'CSV Files (*.csv)'}, ...
            'Select CSV File');
        if file == 0
            return;
        end
        
        state.csvFile = fullfile(path, file);
        
        % Check if defaults file exists
        if ~isempty(state.defaultsFile) && isfile(state.defaultsFile)
            answer = uiconfirm(fig, ...
                'Use defaults file with CSV?', ...
                'Defaults File', ...
                'Options', {'Yes', 'No'}, ...
                'DefaultOption', 'Yes');
            useDefaults = strcmp(answer, 'Yes');
        else
            useDefaults = false;
        end
        
        try
            clearOutput();
            appendOutput(sprintf('Loading CSV: %s', file));
            
            if useDefaults
                % Validate defaults file still exists
                if ~isfile(state.defaultsFile)
                    appendOutput(sprintf('✗ Warning: Defaults file not found: %s', state.defaultsFile));
                    appendOutput('  Loading CSV without defaults...');
                    useDefaults = false;
                end
            end
            
            if useDefaults
                state.packets = ScapyML('fromCSV', state.selectedProtocol, ...
                    state.csvFile, state.defaultsFile, state.conversionFile);
                appendOutput(sprintf('  (using defaults: %s)', state.defaultsFile));
                if ~isempty(state.conversionFile)
                    appendOutput(sprintf('  (using conversions: %s)', state.conversionFile));
                end
            else
                % Load CSV without defaults
                state.packets = {};
                
                % Load conversions if specified
                if ~isempty(state.conversionFile) && isfile(state.conversionFile)
                    converter = ScapyML.ConversionManager(state.conversionFile);
                    appendOutput(sprintf('  (using conversions: %s)', state.conversionFile));
                else
                    converter = ScapyML.ConversionManager();  % Empty - no conversions
                end
                
                % ---- Fast bulk CSV load ----
                % Only protocol-mapped columns are read; conversions are applied
                % once per raw column (never to already-converted data).
                proto        = ScapyML.ProtocolRegistry.instance().get(state.selectedProtocol);
                allFieldDefs = ScapyML.Packet.collectFields(proto.Fields);
                defaultValues = struct();
                for k = 1:numel(allFieldDefs)
                    defaultValues.(allFieldDefs{k}.Name) = allFieldDefs{k}.DefaultVal;
                end
                
                appendOutput('  Reading CSV columns...');
                drawnow;
                data  = ScapyML.CsvLoader.readColumns(state.csvFile, fieldnames(defaultValues), proto);
                nRows = height(data);
                
                wb = waitbar(0, 'Loading CSV...', ...
                    'Name', 'Loading Packets', ...
                    'CreateCancelBtn', 'setappdata(gcbf,''cancelled'',true)');
                setappdata(wb, 'cancelled', false);
                progressFcn = @(i, n) guiLoadProgress(wb, i, n);
                [state.packets, cancelled] = ScapyML.CsvLoader.buildPackets( ...
                    proto, defaultValues, data, converter, progressFcn);
                delete(wb);
                if cancelled
                    appendOutput(sprintf('⚠ Cancelled — loaded %d / %d packets', numel(state.packets), nRows));
                end
            end
            
            appendOutput(sprintf('✓ Created %d packets from CSV', numel(state.packets)));
            btnSend.Enable = 'on';
            btnSaveMAT.Enable = 'on';  % Enable save after packets loaded
        catch ME
            appendOutput(sprintf('✗ Error: %s', ME.message));
            appendOutput(sprintf('  CSV file: %s', state.csvFile));
            if useDefaults
                appendOutput(sprintf('  Defaults file: %s', state.defaultsFile));
            end
        end
    end
    
    function cancel = guiLoadProgress(wb, i, n)
        % Progress callback for CsvLoader.buildPackets; returns true to cancel.
        cancel = false;
        if ~isvalid(wb), cancel = true; return; end
        if getappdata(wb, 'cancelled')
            cancel = true;
            return;
        end
        waitbar(i/n, wb, sprintf('Loading CSV... %d / %d', i, n));
    end

    function sendPackets()
        if isempty(state.currentPacket) && isempty(state.packets)
            appendOutput('No packets to send');
            return;
        end
        
        % Enhanced send dialog with timing options
        sendDlg = uifigure('Name', 'Send UDP Packets', 'Position', [250 200 550 450]);
        sendGrid = uigridlayout(sendDlg, [9 2]);
        sendGrid.RowHeight = {30, 30, 20, 30, 100, 30, 30, 30, 40};  % Row 5 = 100px for button group!
        sendGrid.ColumnWidth = {150, '1x'};
        
        % IP and Port
        uilabel(sendGrid, 'Text', 'Destination IP:', 'FontWeight', 'bold');
        editIP = uieditfield(sendGrid, 'text', 'Value', '127.0.0.1');
        
        uilabel(sendGrid, 'Text', 'Port:', 'FontWeight', 'bold');
        editPort = uieditfield(sendGrid, 'numeric', 'Value', 5000);
        
        % Info text
        lblInfo = uilabel(sendGrid, 'Text', '(unicast or multicast 224.x.x.x)');
        lblInfo.Layout.Column = [1 2];
        lblInfo.FontColor = [0.5 0.5 0.5];
        lblInfo.FontSize = 9;
        
        % Packet count
        if ~isempty(state.packets)
            lblCount = uilabel(sendGrid, 'Text', sprintf('Packets to send: %d', numel(state.packets)));
        else
            lblCount = uilabel(sendGrid, 'Text', 'Packets to send: 1');
        end
        lblCount.Layout.Column = [1 2];
        lblCount.FontWeight = 'bold';
        
        % Send Mode - Button Group (takes full row with 100px height)
        bgMode = uibuttongroup(sendGrid, ...
            'Title', 'Send Mode', ...
            'FontWeight', 'bold', ...
            'SelectionChangedFcn', @(~,evt) modeChanged(evt.NewValue.Text));
        bgMode.Layout.Column = [1 2];
        
        % Radio buttons directly in button group (no grid needed)
        rbSingle = uiradiobutton(bgMode, 'Text', 'Single Send (immediate)', 'Value', true, 'Position', [10 55 300 20]);
        rbPeriodic = uiradiobutton(bgMode, 'Text', 'Periodic Send (continuous)', 'Value', false, 'Position', [10 30 300 20]);
        rbCSV = uiradiobutton(bgMode, 'Text', 'CSV Timestamp-based (replay)', 'Value', false, 'Position', [10 5 300 20]);
        
        % Periodic options
        uilabel(sendGrid, 'Text', 'Interval (seconds):', 'FontWeight', 'bold');
        editInterval = uieditfield(sendGrid, 'numeric', 'Value', 1.0, 'Enable', 'off');
        
        % CSV timestamp options
        uilabel(sendGrid, 'Text', 'Timestamp Column:', 'FontWeight', 'bold');
        editTimestampCol = uieditfield(sendGrid, 'text', 'Value', 'timestamp', 'Enable', 'off');
        
        % Send button
        btnSendNow = uibutton(sendGrid, 'Text', '✓ Send Packet(s)', ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~) doSend());
        btnSendNow.Layout.Column = [1 2];
        
        function modeChanged(mode)
            if contains(mode, 'Periodic')
                editInterval.Enable = 'on';
                editTimestampCol.Enable = 'off';
            elseif contains(mode, 'CSV')
                editInterval.Enable = 'off';
                editTimestampCol.Enable = 'on';
            else
                editInterval.Enable = 'off';
                editTimestampCol.Enable = 'off';
            end
        end
        
        function doSend()
            ip = editIP.Value;
            port = editPort.Value;
            
            % Determine mode
            if rbPeriodic.Value
                mode = 'periodic';
                interval = editInterval.Value;
            elseif rbCSV.Value
                mode = 'csv';
                timestampCol = editTimestampCol.Value;
            else
                mode = 'single';
            end
            
            try
                if ~isempty(state.packets)
                    pkts = state.packets;
                else
                    pkts = {state.currentPacket};
                end
                
                % Create ChecksumManager if checksum file loaded
                if ~isempty(state.checksumFile) && isfile(state.checksumFile)
                    try
                        cm = ScapyML.ChecksumManager(state.checksumFile);
                        appendOutput('  Checksums: ENABLED ✓');
                    catch ME
                        appendOutput(sprintf('⚠️  Warning: Could not load checksums: %s', ME.message));
                        cm = [];
                    end
                else
                    cm = [];
                end
                
                if strcmp(mode, 'single')
                    nPkts = numel(pkts);
                    wb = waitbar(0, 'Sending packets...', ...
                        'Name', 'Sending UDP Packets', ...
                        'CreateCancelBtn', 'setappdata(gcbf,''cancelled'',true)');
                    setappdata(wb, 'cancelled', false);
                    sender = ScapyML.UdpSender(ip, port);
                    sentCount = 0;
                    try
                        for i = 1:nPkts
                            if getappdata(wb, 'cancelled'), break; end
                            bytes = ScapyML.PacketSender.buildPacket(pkts{i}, cm);
                            sender.send(bytes);
                            sentCount = sentCount + 1;
                            waitbar(i/nPkts, wb, sprintf('Sending... %d / %d', i, nPkts));
                        end
                    catch sendErr
                        sender.close();
                        delete(wb);
                        rethrow(sendErr);
                    end
                    sender.close();
                    delete(wb);
                    appendOutput(sprintf('✓ Sent %d / %d packet(s) to %s:%d', sentCount, nPkts, ip, port));
                    close(sendDlg);
                    
                elseif strcmp(mode, 'periodic')
                    close(sendDlg);
                    nPkts = numel(pkts);
                    appendOutput(sprintf('Starting periodic send: %d packets @ %.3f sec intervals', numel(pkts), interval));
                    appendOutput(sprintf('Destination: %s:%d', ip, port));
                    wb = waitbar(0, 'Periodic send...', ...
                        'Name', 'Sending UDP Packets', ...
                        'CreateCancelBtn', 'setappdata(gcbf,''cancelled'',true)');
                    setappdata(wb, 'cancelled', false);
                    sender = ScapyML.UdpSender(ip, port);
                    try
                        for i = 1:nPkts
                            if getappdata(wb, 'cancelled'), break; end
                            tStart = tic;
                            bytes = ScapyML.PacketSender.buildPacket(pkts{i}, cm);
                            sender.send(bytes);
                            waitbar(i/nPkts, wb, sprintf('Periodic send %d / %d', i, nPkts));
                            if i < nPkts
                                nextTime = toc(tStart) + interval;
                                while toc(tStart) < nextTime, end
                            end
                        end
                    catch
                    end
                    sender.close();
                    delete(wb);
                    appendOutput(sprintf('✓ Periodic send complete'));
                    
                elseif strcmp(mode, 'csv')
                    % Extract timestamp data from CSV
                    if isempty(state.csvFile)
                        appendOutput('✗ No CSV file loaded');
                        return;
                    end
                    
                    try
                        data = ScapyML.CsvLoader.readColumns(state.csvFile, {timestampCol});
                        if ~ismember(timestampCol, data.Properties.VariableNames)
                            appendOutput(sprintf('✗ Column "%s" not found in CSV', timestampCol));
                            return;
                        end
                        
                        timestamps = data.(timestampCol);
                        close(sendDlg);
                        nPkts = numel(pkts);
                        appendOutput(sprintf('Starting CSV-timed send: %d packets', nPkts));
                        appendOutput(sprintf('Timestamp column: %s', timestampCol));
                        appendOutput(sprintf('Destination: %s:%d', ip, port));
                        
                        wb = waitbar(0, 'CSV-timed send...', ...
                            'Name', 'Sending UDP Packets', ...
                            'CreateCancelBtn', 'setappdata(gcbf,''cancelled'',true)');
                        setappdata(wb, 'cancelled', false);
                        sender = ScapyML.UdpSender(ip, port);
                        try
                            tStart = tic;
                            bytes = ScapyML.PacketSender.buildPacket(pkts{1}, cm);
                            sender.send(bytes);
                            waitbar(1/nPkts, wb, sprintf('CSV send 1 / %d', nPkts));
                            for i = 2:nPkts
                                if getappdata(wb, 'cancelled'), break; end
                                targetTime = timestamps(i) - timestamps(1);
                                while toc(tStart) < targetTime, end
                                bytes = ScapyML.PacketSender.buildPacket(pkts{i}, cm);
                                sender.send(bytes);
                                waitbar(i/nPkts, wb, sprintf('CSV send %d / %d', i, nPkts));
                            end
                        catch
                        end
                        sender.close();
                        delete(wb);
                        appendOutput('✓ CSV-timed send complete');
                    catch ME
                        appendOutput(sprintf('✗ Error reading timestamps: %s', ME.message));
                    end
                end
                
            catch ME
                appendOutput(sprintf('✗ Error: %s', ME.message));
            end
        end
    end
    
    function generateWireshark()
        if isempty(state.loadedProtocols)
            appendOutput('No protocols loaded');
            return;
        end
        
        % Protocol selection dialog - improved layout
        selectDlg = uifigure('Name', 'Create Wireshark Dissector', ...
            'Position', [300 250 550 450]);
        selectGrid = uigridlayout(selectDlg, [5 1]);
        selectGrid.RowHeight = {40, '1x', 50, 50, 40};  % More space for port and buttons
        
        % Instruction label
        lblInst = uilabel(selectGrid, ...
            'Text', 'Select protocols to include in dissector:', ...
            'FontWeight', 'bold', ...
            'FontSize', 12);
        
        % Listbox for protocol selection
        listProtos = uilistbox(selectGrid, ...
            'Items', state.loadedProtocols, ...
            'Multiselect', 'on', ...
            'Value', state.loadedProtocols(1));
        
        % Port input with better layout
        portPanel = uipanel(selectGrid);
        portGrid = uigridlayout(portPanel, [1 2]);
        portGrid.ColumnWidth = {120, '1x'};
        uilabel(portGrid, 'Text', 'UDP Port:', 'FontWeight', 'bold', 'FontSize', 11);
        editPort = uieditfield(portGrid, 'numeric', 'Value', 5000, ...
            'FontSize', 11, ...
            'Limits', [1 65535]);
        
        % Info text
        uilabel(selectGrid, ...
            'Text', 'The dissector will be registered on the specified UDP port', ...
            'FontSize', 9, ...
            'FontColor', [0.4 0.4 0.4]);
        
        % Buttons with clear labels
        btnGrid = uigridlayout(selectGrid, [1 2]);
        btnGrid.ColumnWidth = {'1x', '1x'};
        uibutton(btnGrid, 'Text', '✓ Create Dissector', ...
            'FontWeight', 'bold', ...
            'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~) doGenerate());
        uibutton(btnGrid, 'Text', '✗ Cancel', ...
            'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~) close(selectDlg));
        
        function doGenerate()
            selectedProtos = listProtos.Value;
            if isempty(selectedProtos)
                uialert(selectDlg, 'Please select at least one protocol', 'No Selection');
                return;
            end
            
            if ~iscell(selectedProtos)
                selectedProtos = {selectedProtos};
            end
            
            port = editPort.Value;
            
            % For multiple protocols, configure discriminator first
            if numel(selectedProtos) > 1
                close(selectDlg);
                configureDiscriminator(selectedProtos, port);
                return;
            end
            
            % Generate filename
            if numel(selectedProtos) == 1
                defaultName = sprintf('%s_dissector.lua', selectedProtos{1});
            else
                defaultName = 'multi_protocol_dissector.lua';
            end
            
            [file, path] = uiputfile('*.lua', 'Save Wireshark Dissector', defaultName);
            if file == 0
                return;
            end
            
            fullPath = fullfile(path, file);
            close(selectDlg);
            
            try
                clearOutput();
                
                % Single protocol
                ScapyML('dissector', selectedProtos{1}, fullPath, port);
                appendOutput(sprintf('✓ Wireshark dissector created: %s', file));
                appendOutput(sprintf('  Protocol: %s', selectedProtos{1}));
                
                appendOutput(sprintf('  Registered on UDP port: %d', port));
                appendOutput('');
                appendOutput('Installation:');
                appendOutput('  1. Copy .lua file to Wireshark plugins folder');
                appendOutput('  2. Restart Wireshark');
                appendOutput('  3. Capture UDP traffic on port ' + string(port));
                
            catch ME
                appendOutput(sprintf('✗ Error: %s', ME.message));
            end
        end
    end
    
    function configureDiscriminator(selectedProtos, port)
        % Configure message ID discriminator for multi-protocol dissector
        
        discDlg = uifigure('Name', 'Configure Message ID Discriminator', ...
            'Position', [250 200 700 550]);
        discGrid = uigridlayout(discDlg, [7 1]);
        discGrid.RowHeight = {50, 30, 80, '1x', 60, 50, 40};
        
        % Title and explanation
        titlePanel = uipanel(discGrid, 'BackgroundColor', [0.95 0.95 1]);
        titleGrid = uigridlayout(titlePanel, [2 1]);
        titleGrid.RowHeight = {25, 20};
        uilabel(titleGrid, 'Text', '🦈 Multi-Protocol Message ID Configuration', ...
            'FontWeight', 'bold', 'FontSize', 13, 'HorizontalAlignment', 'center');
        uilabel(titleGrid, 'Text', 'Configure how Wireshark identifies each protocol by message ID', ...
            'FontSize', 10, 'HorizontalAlignment', 'center', 'FontColor', [0.3 0.3 0.5]);
        
        % Selected protocols info
        uilabel(discGrid, 'Text', sprintf('Selected protocols: %s', strjoin(selectedProtos, ', ')), ...
            'FontWeight', 'bold', 'FontSize', 11);
        
        % Default discriminator settings
        defaultPanel = uipanel(discGrid, 'Title', 'Default Discriminator Settings', ...
            'FontWeight', 'bold', 'FontSize', 11);
        defaultGrid = uigridlayout(defaultPanel, [3 2]);
        defaultGrid.ColumnWidth = {150, '1x'};
        defaultGrid.RowHeight = {25, 25, 25};
        
        uilabel(defaultGrid, 'Text', 'Field Name:', 'FontWeight', 'bold');
        editFieldName = uieditfield(defaultGrid, 'text', 'Value', 'msg_id');
        
        uilabel(defaultGrid, 'Text', 'Byte Offset:', 'FontWeight', 'bold');
        editOffset = uieditfield(defaultGrid, 'numeric', 'Value', 0, 'Limits', [0 255]);
        
        uilabel(defaultGrid, 'Text', 'Field Size (bytes):', 'FontWeight', 'bold');
        ddSize = uidropdown(defaultGrid, 'Items', {'1', '2', '4'}, 'Value', '1');
        
        % Protocol-specific message ID table
        tablePanel = uipanel(discGrid, 'Title', 'Protocol Message IDs', ...
            'FontWeight', 'bold', 'FontSize', 11);
        tableGrid = uigridlayout(tablePanel, [2 1]);
        tableGrid.RowHeight = {'1x', 30};
        
        % Create table data
        tableData = cell(numel(selectedProtos), 3);
        for i = 1:numel(selectedProtos)
            tableData{i, 1} = selectedProtos{i};
            tableData{i, 2} = sprintf('0x%02X', i);  % Default: 0x01, 0x02, etc.
            tableData{i, 3} = 'msg_id at offset 0, size 1';
        end
        
        tbl = uitable(tableGrid, ...
            'Data', tableData, ...
            'ColumnName', {'Protocol', 'Message ID (hex)', 'Configuration'}, ...
            'ColumnWidth', {200, 150, 'auto'}, ...
            'ColumnEditable', [false true false], ...
            'FontSize', 10);
        
        % Update button for table
        btnUpdateTable = uibutton(tableGrid, 'Text', '↻ Apply Defaults to All', ...
            'FontSize', 10, ...
            'ButtonPushedFcn', @(~,~) updateTableFromDefaults());
        
        % Help text
        helpPanel = uipanel(discGrid, 'BackgroundColor', [1 1 0.9]);
        helpGrid = uigridlayout(helpPanel, [3 1]);
        helpGrid.RowHeight = {18, 18, 18};
        uilabel(helpGrid, 'Text', '💡 Tips:', 'FontWeight', 'bold', 'FontSize', 10);
        uilabel(helpGrid, 'Text', '• Message ID is the field used to identify which protocol a packet belongs to', ...
            'FontSize', 9);
        uilabel(helpGrid, 'Text', '• Each protocol must have a UNIQUE message ID value', ...
            'FontSize', 9);
        
        % Action buttons
        btnGrid = uigridlayout(discGrid, [1 3]);
        btnGrid.ColumnWidth = {'1x', 150, 150};
        
        uibutton(btnGrid, 'Text', '💾 Save Config...', ...
            'FontSize', 10, ...
            'ButtonPushedFcn', @(~,~) saveConfig());
        
        uibutton(btnGrid, 'Text', '✓ Generate Dissector', ...
            'FontWeight', 'bold', ...
            'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~) doGenerateMulti());
        
        uibutton(btnGrid, 'Text', '✗ Cancel', ...
            'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~) close(discDlg));
        
        function updateTableFromDefaults()
            % BUG FIX: this function previously assigned a local variable
            % literally named 'size', which shadows MATLAB's builtin
            % size() function. Because this is a nested function sharing
            % configureDiscriminator's workspace with createConfigFromTable()
            % and doGenerateMulti() (both of which call size(tableData,1)),
            % clicking "Apply Defaults to All" before "Generate Dissector"
            % would leave 'size' shadowed as a plain number for the rest of
            % the dialog's lifetime, breaking those sibling functions'
            % size(tableData,1) calls too. Renamed to fieldSize.
            fieldName = editFieldName.Value;
            offset = editOffset.Value;
            fieldSize = str2double(ddSize.Value);
            
            configStr = sprintf('%s at offset %d, size %d', fieldName, offset, fieldSize);
            
            for i = 1:size(tableData, 1)
                tableData{i, 3} = configStr;
            end
            tbl.Data = tableData;
        end
        
        function saveConfig()
            % Save discriminator configuration to file
            try
                config = createConfigFromTable();
                [file, path] = uiputfile('*.txt', 'Save Discriminator Configuration', ...
                    'discriminator_config.txt');
                if file ~= 0
                    config.saveToFile(fullfile(path, file));
                    uialert(discDlg, sprintf('Configuration saved to %s', file), ...
                        'Saved', 'Icon', 'success');
                end
            catch ME
                uialert(discDlg, ME.message, 'Error Saving');
            end
        end
        
        function config = createConfigFromTable()
            % Create DiscriminatorConfig from table data
            %
            % BUG FIX (KI-NEW-02): this function previously called
            % config.setDefaults(...) and config.addMappingSimple(...),
            % neither of which exist on ScapyML.DiscriminatorConfig (the
            % real methods are addProtocol/setGlobalConfig/etc. -- see
            % STR.md Known Issues). Every call to this function
            % immediately threw "Undefined method". Rewritten below to
            % use the real API: addProtocol(name, fieldName, offset,
            % size, value) is called once per protocol row, since this
            % dialog's table lets every protocol share the same
            % discriminator field/offset/size and differ only in value.
            config = ScapyML.DiscriminatorConfig();
            
            fieldName = editFieldName.Value;
            offset = editOffset.Value;
            fieldSize = str2double(ddSize.Value);
            
            % Add each protocol's discriminator mapping.
            for i = 1:size(tableData, 1)
                protoName = tableData{i, 1};
                msgIdStr = tableData{i, 2};
                
                % Parse message ID (hex or decimal)
                msgIdStr = strtrim(msgIdStr);
                if startsWith(lower(msgIdStr), '0x')
                    msgId = hex2dec(msgIdStr(3:end));
                else
                    msgId = str2double(msgIdStr);
                end
                
                if isnan(msgId)
                    error('Invalid message ID for %s: %s', protoName, msgIdStr);
                end
                
                config.addProtocol(protoName, fieldName, offset, fieldSize, msgId);
            end
            
            return;
        end
        
        function doGenerateMulti()
            % Validate and generate multi-protocol dissector
            try
                % Create discriminator config
                config = createConfigFromTable();
                
                % Validate unique message IDs
                msgIds = containers.Map();
                for i = 1:size(tableData, 1)
                    msgIdStr = strtrim(tableData{i, 2});
                    if startsWith(lower(msgIdStr), '0x')
                        msgId = hex2dec(msgIdStr(3:end));
                    else
                        msgId = str2double(msgIdStr);
                    end
                    
                    if msgIds.isKey(num2str(msgId))
                        uialert(discDlg, ...
                            sprintf('Duplicate message ID %s for protocols %s and %s', ...
                            msgIdStr, msgIds(num2str(msgId)), tableData{i, 1}), ...
                            'Duplicate Message ID', 'Icon', 'error');
                        return;
                    end
                    msgIds(num2str(msgId)) = tableData{i, 1};
                end
                
                % Get filename
                [file, path] = uiputfile('*.lua', 'Save Wireshark Dissector', ...
                    'multi_protocol_dissector.lua');
                if file == 0
                    return;
                end
                
                fullPath = fullfile(path, file);
                close(discDlg);
                
                % Generate dissector
                clearOutput();
                
                % BUG FIX (KI-NEW-02): reg.Enums is a PRIVATE property on
                % ProtocolRegistry and cannot be accessed from outside the
                % class; this used to throw "Enums is Private" before
                % ever reaching MultiProtocolDissector.generate(). Build
                % the enum list via the public listEnums()/getEnum() API
                % instead, matching the pattern already used by ScapyML.m's
                % own working single-protocol 'dissector' command.
                reg = ScapyML.ProtocolRegistry.instance();
                enumNames = reg.listEnums();
                enumDefs = {};
                for k = 1:numel(enumNames)
                    enumDefs{k} = reg.getEnum(enumNames{k}); %#ok<AGROW>
                end
                
                ScapyML.MultiProtocolDissector.generate(selectedProtos, fullPath, ...
                    port, enumDefs, config);
                
                appendOutput(sprintf('✓ Multi-protocol Wireshark dissector created: %s', file));
                appendOutput('  Discrimination: Message ID based');
                appendOutput(sprintf('  Discriminator: %s at offset %d, size %d bytes', ...
                    editFieldName.Value, editOffset.Value, str2double(ddSize.Value)));
                appendOutput('  Protocols:');
                for i = 1:numel(selectedProtos)
                    % BUG FIX (KI-NEW-02): config.getMapping() does not
                    % exist on DiscriminatorConfig; the real accessor is
                    % getProtocolValue().
                    msgIdValue = config.getProtocolValue(selectedProtos{i});
                    appendOutput(sprintf('    %d. %s (ID=0x%02X)', i, selectedProtos{i}, msgIdValue));
                end
                appendOutput(sprintf('  Registered on UDP port: %d', port));
                appendOutput('');
                appendOutput('Installation:');
                appendOutput('  1. Copy .lua file to Wireshark plugins folder');
                appendOutput('  2. Restart Wireshark');
                appendOutput('  3. Capture UDP traffic on port ' + string(port));
                appendOutput('');
                appendOutput('✓ Wireshark will use message ID to identify protocols!');
                
            catch ME
                uialert(discDlg, ME.message, 'Error', 'Icon', 'error');
            end
        end
    end
    
    function clearProtocols()
        % Clear all loaded protocols and reset state
        try
            % Get registry instance and clear all protocols
            reg = ScapyML.ProtocolRegistry.instance();
            reg.clearAll();
            
            % Reset state
            state.loadedProtocols = {};
            state.selectedProtocol = '';
            state.currentPacket = [];
            state.packets = {};
            state.defaultsFile = '';
            state.csvFile = '';
            state.conversionFile = '';
            state.checksumFile = '';
            
            % Reset dropdown
            ddProtocol.Items = {'(Select Protocol)'};
            ddProtocol.Value = '(Select Protocol)';
            
            % Disable protocol-dependent buttons
            btnShowInfo.Enable = 'off';
            btnCreatePacket.Enable = 'off';
            btnEditPacket.Enable = 'off';
            btnShowPacket.Enable = 'off';
            btnHexDump.Enable = 'off';
            btnDefaults.Enable = 'off';
            btnConversions.Enable = 'off';
            btnChecksums.Enable = 'off';
            btnLoadCSV.Enable = 'off';
            btnSaveMAT.Enable = 'off';
            btnLoadMAT.Enable = 'off';
            btnSend.Enable = 'off';
            btnWireshark.Enable = 'off';
            
            appendOutput('═══════════════════════════════════════════');
            appendOutput('✓ All protocols cleared');
            appendOutput('═══════════════════════════════════════════');
            appendOutput('Ready to load new protocols');
        catch ME
            appendOutput(sprintf('✗ Error clearing protocols: %s', ME.message));
        end
    end
    
    function result = ternary(cond, trueVal, falseVal)
        if cond
            result = trueVal;
        else
            result = falseVal;
        end
    end
end
