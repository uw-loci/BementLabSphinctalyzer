classdef testUpdateChannelNames < matlab.unittest.TestCase
    % Renaming channels in the results .mat file during post-processing
    % (updateChannelNamesInResultsMatFile), on temporary copies of the
    % legacy fixture (channels channel1 and channel2, reference channel2).

    properties
        TestsDir
        Original   % SphinctalyzerOutputs and InputCells of the fixture
    end

    methods (TestClassSetup)
        function addPaths(testCase)
            testCase.TestsDir = fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testCase.TestsDir,'..','src')));
            testCase.Original = load(fullfile(testCase.TestsDir,'fixtures','legacy_sub1','sphincRedo','sphinctalyzerResults.mat'), ...
                'SphinctalyzerOutputs','InputCells');
        end
    end

    methods (Test)
        function renameBothChannels(testCase)
            [results, message, out] = testCase.rename({'GFP';'mCherry'});
            testCase.verifyNotEmpty(out, message);
            testCase.verifyEqual(results.InputCells(:,1), {'GFP';'mCherry'});
            testCase.verifyDataMoved(results, {'channel1','channel2'}, {'GFP','mCherry'});
            testCase.verifyEqual(results.SphinctalyzerOutputs(1).RefChannel, {'mCherry'});
        end

        function namesWithSpacesHyphensAndDigits(testCase)
            cases = {{'GFP actin';'mCherry'}, {'GFPActin','mCherry'}; ...
                     {'mCh-wGBD';'GFP-CTTN'}, {'mCh_wGBD','GFP_CTTN'}; ...
                     {'488nm';'561nm'},       {'x488nm','x561nm'}};
            for c = 1:size(cases,1)
                [results, message, out] = testCase.rename(cases{c,1});
                testCase.verifyNotEmpty(out, message);
                testCase.verifyEqual(results.InputCells(:,1), cases{c,1});
                testCase.verifyDataMoved(results, {'channel1','channel2'}, cases{c,2});
            end
        end

        function renameOneChannel(testCase)
            [results, message, out] = testCase.rename({'GFP';'channel2'});
            testCase.verifyNotEmpty(out, message);
            testCase.verifyDataMoved(results, {'channel1','channel2'}, {'GFP','channel2'});
            testCase.verifyEqual(results.SphinctalyzerOutputs(1).RefChannel, {'channel2'});
        end

        function swapNames(testCase)
            [results, message, out] = testCase.rename({'channel2';'channel1'});
            testCase.verifyNotEmpty(out, message);
            % the data follows the channel: channel1's data is now under channel2
            testCase.verifyDataMoved(results, {'channel1','channel2'}, {'channel2','channel1'});
            testCase.verifyEqual(results.SphinctalyzerOutputs(1).RefChannel, {'channel1'});
        end

        function oldNamesWithSpaces(testCase)
            work = testCase.workingCopy();
            testCase.renameIn(work, {'Portain A';'Protein B'});
            [results, message, out] = testCase.renameIn(work, {'Protein A';'Protein B'});
            testCase.verifyNotEmpty(out, message);
            testCase.verifyEqual(results.InputCells(:,1), {'Protein A';'Protein B'});
            testCase.verifyDataMoved(results, {'channel1','channel2'}, {'ProteinA','ProteinB'});
        end

        function rejectedNamesLeaveFileUnchanged(testCase)
            rejected = {{'GFP';'GFP'}, 'different'; ...
                        {'GFP-1';'GFP_1'}, 'same name'; ...
                        {'GFP';''}, 'empty'; ...
                        {'Self';'GFP'}, 'Self'; ...
                        {'GFP'}, 'channels'};
            for c = 1:size(rejected,1)
                work = testCase.workingCopy();
                resultsFile = fullfile(work,'sphincRedo','sphinctalyzerResults.mat');
                before = fileread_bytes(resultsFile);
                [~, message, out] = testCase.renameIn(work, rejected{c,1});
                testCase.verifyEmpty(out);
                testCase.verifySubstring(message, rejected{c,2});
                testCase.verifyEqual(fileread_bytes(resultsFile), before, 'The results file should not change');
            end
        end

        function unchangedNamesDoNotRewriteFile(testCase)
            work = testCase.workingCopy();
            resultsFile = fullfile(work,'sphincRedo','sphinctalyzerResults.mat');
            before = dir(resultsFile);
            [~, message, out] = testCase.renameIn(work, {'channel1';'channel2'});
            testCase.verifyEmpty(out);
            testCase.verifyEqual(message, 'Channel names are unchanged.');
            testCase.verifyEqual(dir(resultsFile).datenum, before.datenum);
            testCase.verifyFalse(isfile(fullfile(work,'sphinctalyzerResults_bak.mat')));
        end

        function postProcessingAfterRename(testCase)
            work = testCase.workingCopy();
            [~, message, out] = testCase.renameIn(work, {'GFP actin';'mCh-wGBD'});
            testCase.assertNotEmpty(out, message);
            evalc('createNewMovie_post(work)');
            resultsFile = fullfile(work,'sphincRedo','Results_1.xlsx');
            header = readcell(resultsFile,'Sheet','Peak Locations','Range','C1:D1');
            testCase.verifyEqual(header, {'GFP actin','mCh-wGBD'});
            % same values as post-processing without the rename
            expected = load(fullfile(testCase.TestsDir,'fixtures','legacy_sub1_expected.mat'),'expected');
            locations = readmatrix(resultsFile,'Sheet','Peak Locations','Range','B2');
            testCase.verifyEqual(locations(:,2:3), -expected.expected.peakLocations(:,2:3), 'AbsTol', 1e-9);
        end
    end

    methods
        function work = workingCopy(testCase)
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            work = fullfile(tempFolder.Folder,'legacy_sub1');
            copyfile(fullfile(testCase.TestsDir,'fixtures','legacy_sub1'), work);
        end

        function [results, message, out] = rename(testCase, newNames)
            [results, message, out] = testCase.renameIn(testCase.workingCopy(), newNames);
        end

        function [results, message, out] = renameIn(~, work, newNames)
            load(fullfile(work,'parameters.mat'),'parameters');
            obj = parameters;
            obj.filePath = fullfile(work,'sphinc','sphinctalyzerResults.mat');
            evalc('[out, message] = updateChannelNamesInResultsMatFile(obj, {}, newNames);');
            results = load(fullfile(work,'sphincRedo','sphinctalyzerResults.mat'),'SphinctalyzerOutputs','InputCells');
        end

        function verifyDataMoved(testCase, results, oldPrefixes, newPrefixes)
            % every channel field of the fixture is found under the new
            % prefix with identical data, and no old channel field is left
            original = testCase.Original.SphinctalyzerOutputs;
            newFields = fieldnames(results.SphinctalyzerOutputs);
            testCase.verifyEqual(numel(newFields), numel(fieldnames(original)));
            for iC = 1:numel(oldPrefixes)
                oldFields = fieldnames(original);
                oldFields = oldFields(startsWith(oldFields, oldPrefixes{iC}));
                for f = 1:numel(oldFields)
                    newField = [newPrefixes{iC} oldFields{f}(numel(oldPrefixes{iC})+1:end)];
                    testCase.assertTrue(any(strcmp(newFields, newField)), ['Missing field ' newField]);
                    testCase.verifyEqual({results.SphinctalyzerOutputs.(newField)}, {original.(oldFields{f})}, newField);
                end
            end
            testCase.verifyEqual([results.SphinctalyzerOutputs.InRange], [original.InRange]);
        end
    end
end

function bytes = fileread_bytes(file)
fid = fopen(file,'r');
bytes = fread(fid,'*uint8');
fclose(fid);
end
