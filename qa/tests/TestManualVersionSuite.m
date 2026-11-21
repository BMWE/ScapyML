classdef TestManualVersionSuite < matlab.unittest.TestCase
% The version in code, README.md and REQUIREMENTS.md must agree
% (the version is bumped on every GitHub upload).

    methods (Test)
        function tcVersionMatchesDocs(testCase)
            v = ScapyML.Version.current();
            testCase.verifyTrue(~isempty(regexp(v, '^\d+\.\d+\.\d+$', 'once')));
            root = fileparts(which('ScapyML'));
            for f = {'README.md', 'REQUIREMENTS.md'}
                p = fullfile(root, f{1});
                if ~isfile(p), continue; end
                txt = fileread(p);
                tok = regexp(txt, '\*\*Version:\*\*\s*([0-9.]+)', 'tokens', 'once');
                testCase.verifyNotEmpty(tok, [f{1} ' has no Version line']);
                if ~isempty(tok)
                    testCase.verifyEqual(tok{1}, v, [f{1} ' version differs from ScapyML.Version']);
                end
            end
        end
    end
end
