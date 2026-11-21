classdef Version
% ScapyML.Version - single source of the release version number.
% Keep in sync with README.md and REQUIREMENTS.md (bumped on every GitHub upload;
% qa/tests/TestManualVersionSuite.m checks this).

    methods (Static)
        function v = current()
            v = '2.3.8';
        end
    end
end
