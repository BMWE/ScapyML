classdef TestManualLongNamesSuite < matlab.unittest.TestCase
% Field names built from nested structs must fit MATLAB's 63-character limit
% (namelengthmax), stay unique, and remain usable (Packet set/get, CSV).

    properties
        TempFolder
        HeaderFile
    end

    methods (TestClassSetup)
        function classSetup(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.TempFolder = testCase.applyFixture(TemporaryFolderFixture).Folder;
            testCase.HeaderFile = fullfile(testCase.TempFolder, 'long.h');
            fid = fopen(testCase.HeaderFile, 'w');
            fprintf(fid, 'typedef struct { uint8_t very_long_leaf_field_name_number_one; uint8_t very_long_leaf_field_name_number_two; } InnerStructureWithAVeryLongName;\n');
            fprintf(fid, 'typedef struct { InnerStructureWithAVeryLongName first_member_of_the_outer_structure; InnerStructureWithAVeryLongName second_member_of_the_outer_structure; } LongOuter;\n');
            fclose(fid);
        end
    end

    methods (TestMethodSetup)
        function clearRegistry(~)
            ScapyML.ProtocolRegistry.instance().clearAll();
        end
    end

    methods (Access = private)
        function protos = parseQuiet(testCase)
            w = warning('off', 'ScapyML:HeaderParser:NameShortened');
            c = onCleanup(@() warning(w));
            protos = ScapyML.HeaderParser.parseFile(testCase.HeaderFile, 'big');
            reg = ScapyML.ProtocolRegistry.instance();
            for k = 1:numel(protos), reg.register(protos{k}); end
        end
    end

    methods (Test)

        function tcShortenedNamesWarnOnce(testCase)
            testCase.verifyWarning(@() ScapyML.HeaderParser.parseFile(testCase.HeaderFile, 'big'), ...
                'ScapyML:HeaderParser:NameShortened');
        end

        function tcAllNamesFitAndAreUnique(testCase)
            protos = testCase.parseQuiet();
            outer = protos{2};
            names = outer.fieldNames();
            testCase.verifyEqual(numel(names), 4);
            testCase.verifyTrue(all(cellfun(@numel, names) <= namelengthmax), ...
                'every field name must be <= 63 characters');
            testCase.verifyEqual(numel(unique(names)), numel(names), 'names must be unique');
        end

        function tcOriginalNameIsKept(testCase)
            protos = testCase.parseQuiet();
            fds = ScapyML.Packet.collectFields(protos{2}.Fields);
            full = cellfun(@(f) f.FullName, fds, 'UniformOutput', false);
            testCase.verifyTrue(any(strcmp(full, ...
                'first_member_of_the_outer_structure_very_long_leaf_field_name_number_one')));
        end

        function tcPacketSetGetAndBuildWork(testCase)
            testCase.parseQuiet();
            pkt = ScapyML.Packet('LongOuter');
            names = pkt.fieldNames();
            for i = 1:numel(names)
                pkt.set(names{i}, i);
            end
            testCase.verifyEqual(pkt.build(), uint8([1 2 3 4]));
        end

        function tcCsvAcceptsOriginalLongHeaderAndBareName(testCase)
            testCase.parseQuiet();
            f = fullfile(testCase.TempFolder, 'long.csv');
            fid = fopen(f, 'w');
            fprintf(fid, 'very_long_leaf_field_name_number_one\n9\n');   % bare name: ambiguous (2 members)
            fclose(fid);
            w = warning('off', 'ScapyML:CsvLoader:AmbiguousColumn');
            pkts = ScapyML_fromCSV('LongOuter', f);
            warning(w);
            testCase.verifyEqual(numel(pkts), 1);   % loads without error
        end

        function tcTwoLevelNestingIsNotDoubled(testCase)
            f = fullfile(testCase.TempFolder, 'two.h');
            fid = fopen(f, 'w');
            fprintf(fid, 'typedef struct { uint8_t x; uint8_t y; } Pos2;\n');
            fprintf(fid, 'typedef struct { Pos2 pos; } Mid;\n');
            fprintf(fid, 'typedef struct { Mid m; } Top;\n');
            fclose(fid);
            protos = ScapyML.HeaderParser.parseFile(f, 'big');
            names = protos{3}.fieldNames();
            testCase.verifyEqual(sort(names(:)'), sort({'m_pos_x', 'm_pos_y'}));
        end

    end
end
