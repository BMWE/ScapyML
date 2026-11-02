classdef TestManualCsvStructSuite < matlab.unittest.TestCase
% CSV columns for fields inside a nested struct must load, however the
% header is spelled: pos_x, pos.x, "Pos X", or the bare C name x (when unique).

    properties
        TempFolder
    end

    methods (TestClassSetup)
        function classSetup(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.TempFolder = testCase.applyFixture(TemporaryFolderFixture).Folder;
        end
    end

    methods (TestMethodSetup)
        function loadProtocol(testCase)
            ScapyML.ProtocolRegistry.instance().clearAll();
            h = fullfile(testCase.TempFolder, 'msg.h');
            fid = fopen(h, 'w');
            fprintf(fid, 'typedef struct { uint8_t x; uint8_t y; } Pos;\n');
            fprintf(fid, 'typedef struct { uint8_t id; Pos pos; } Msg;\n');
            fprintf(fid, 'typedef struct { Pos a; Pos b; } Two;\n');
            fclose(fid);
            protos = ScapyML.HeaderParser.parseFile(h, 'big');
            reg = ScapyML.ProtocolRegistry.instance();
            for k = 1:numel(protos), reg.register(protos{k}); end
        end
    end

    methods (Access = private)
        function f = csv(testCase, name, header, row)
            f = fullfile(testCase.TempFolder, name);
            fid = fopen(f, 'w');
            fprintf(fid, '%s\n%s\n', header, row);
            fclose(fid);
        end

        function verifyLoaded(testCase, f)
            pkts = ScapyML_fromCSV('Msg', f);
            testCase.verifyEqual(numel(pkts), 1);
            testCase.verifyEqual(double(pkts{1}.get('id')), 7);
            testCase.verifyEqual(double(pkts{1}.get('pos_x')), 11);
            testCase.verifyEqual(double(pkts{1}.get('pos_y')), 22);
        end
    end

    methods (Test)

        function tcFullPrefixedNames(testCase)
            testCase.verifyLoaded(testCase.csv('a.csv', 'id,pos_x,pos_y', '7,11,22'));
        end

        function tcDottedNames(testCase)
            testCase.verifyLoaded(testCase.csv('b.csv', 'id,pos.x,pos.y', '7,11,22'));
        end

        function tcBareFieldNames(testCase)
            testCase.verifyLoaded(testCase.csv('c.csv', 'id,x,y', '7,11,22'));
        end

        function tcCaseInsensitive(testCase)
            testCase.verifyLoaded(testCase.csv('d.csv', 'ID,Pos_X,POS_Y', '7,11,22'));
        end

        function tcAmbiguousBareNameWarnsAndIsSkipped(testCase)
            f = testCase.csv('e.csv', 'x,a_y', '5,9');
            testCase.verifyWarning(@() ScapyML_fromCSV('Two', f), ...
                'ScapyML:CsvLoader:AmbiguousColumn');
            w = warning('off', 'ScapyML:CsvLoader:AmbiguousColumn');
            pkts = ScapyML_fromCSV('Two', f);
            warning(w);
            testCase.verifyEqual(double(pkts{1}.get('a_y')), 9);
            testCase.verifyEqual(double(pkts{1}.get('a_x')), 0);   % not loaded
        end

        function tcLegacyCsvLoaderPathAlsoResolves(testCase)
            f = testCase.csv('g.csv', 'id,x,y', '7,11,22');
            pkts = ScapyML.CsvLoader.load(f, 'Msg');
            testCase.verifyEqual(double(pkts{1}.get('pos_y')), 22);
        end

    end
end
