classdef testLegacyPostProcessing < matlab.unittest.TestCase
    % Regression test: data analyzed by earlier versions (saved with a
    % negative x axis, e.g. [-28.8 9.6 0]) can still be post-processed, and
    % the output uses positive distances from wound center.
    %
    % fixtures/legacy_sub1 is an analyzed folder from an earlier version.
    % fixtures/legacy_sub1_expected.mat holds the Results_1.xlsx values the
    % code produced on it before the positive x axis change (commit bda1fe0).
    %
    % The folder is post-processed twice: with the default closing check
    % basis (peak position, compared with the expected values) and with the
    % ring area basis (issue #18).

    properties
        Expected
        ResultsFile
        AreaResultsFile
        MovieFile
        NChannels
    end

    methods (TestClassSetup)
        function runPostProcessing(testCase)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testsDir = fileparts(mfilename('fullpath'));
            testCase.applyFixture(PathFixture(fullfile(testsDir,'..','src')));
            tempFolder = testCase.applyFixture(TemporaryFolderFixture);

            % post-processing overwrites Results_1.xlsx, so work on a copy
            workFolder = fullfile(tempFolder.Folder,'legacy_sub1');
            copyfile(fullfile(testsDir,'fixtures','legacy_sub1'), workFolder);
            loaded = load(fullfile(testsDir,'fixtures','legacy_sub1_expected.mat'),'expected');
            testCase.Expected = loaded.expected;
            testCase.NChannels = (size(testCase.Expected.peakLocations,2)-1)/3;

            evalc('createNewMovie_post(workFolder)'); % suppress the per-frame log
            testCase.ResultsFile = fullfile(workFolder,'sphincRedo','Results_1.xlsx');
            movies = dir(fullfile(workFolder,'sphincRedo','*_scan_movietalyzerResults_1.avi'));
            testCase.assertNotEmpty(movies, 'No movie was created');
            testCase.MovieFile = fullfile(movies(1).folder, movies(1).name);

            % second copy with the closing check based on the ring area
            areaFolder = fullfile(tempFolder.Folder,'legacy_sub1_area');
            copyfile(fullfile(testsDir,'fixtures','legacy_sub1'), areaFolder);
            setClosingCheckBasis(fullfile(areaFolder,'parameters_post.xlsx'), 'area');
            evalc('createNewMovie_post(areaFolder)');
            testCase.AreaResultsFile = fullfile(areaFolder,'sphincRedo','Results_1.xlsx');
        end
    end

    methods (Test)
        function peakLocationsArePositiveDistances(testCase)
            new = readmatrix(testCase.ResultsFile,'Sheet','Peak Locations','Range','B2');
            old = testCase.Expected.peakLocations;
            locs = 2:1+testCase.NChannels;
            testCase.verifyEqual(new(:,1), old(:,1), 'Frame index changed');
            testCase.verifyEqual(new(:,locs), -old(:,locs), 'AbsTol', 1e-9);
            testCase.verifyGreaterThanOrEqual(new(~isnan(new(:,locs))), 0);
        end

        function instantaneousPeakLocationsFlipSign(testCase)
            new = readmatrix(testCase.ResultsFile,'Sheet','Peak Locations','Range','B2');
            old = testCase.Expected.peakLocations;
            n = testCase.NChannels;
            instant = 2+n:1+2*n;
            velocity = 2+2*n:1+3*n;
            testCase.verifyEqual(new(:,instant), -old(:,instant), 'AbsTol', 1e-9);
            testCase.verifyEqual(new(:,velocity), old(:,velocity), 'AbsTol', 1e-9, ...
                'Instantaneous velocity is an absolute value and should not change');
        end

        function otherResultsAreUnchanged(testCase)
            sheets = {'Peak Intensity','peakIntensity'; ...
                'Halfwidths','halfwidths'; ...
                'AUCs','aucs'; ...
                'Percent Above Background','percentAboveBackground'};
            for s = 1:size(sheets,1)
                new = readmatrix(testCase.ResultsFile,'Sheet',sheets{s,1},'Range','B2');
                testCase.verifyEqual(new, testCase.Expected.(sheets{s,2}), 'AbsTol', 1e-9, sheets{s,1});
            end
        end

        function closingVelocityAndCheckpointsAreUnchanged(testCase)
            new = readmatrix(testCase.ResultsFile,'Sheet','Closing Velocity and Location','Range','C2');
            testCase.verifyEqual(new, testCase.Expected.closingVelocityLocation, 'AbsTol', 1e-9);
        end

        function xAxisParameterIsConverted(testCase)
            parameters = readcell(testCase.ResultsFile,'Sheet','parameters');
            testCase.verifyEqual(testCase.Expected.xMinStepMax, [-28.8 9.6 0], 'AbsTol', 1e-12, ...
                'Fixture should hold a legacy negative x axis');
            testCase.verifyEqual(str2num(parameters{8,2}), [0 9.6 28.8], 'AbsTol', 1e-12); %#ok<ST2NM>
        end

        function movieHasAllFrames(testCase)
            movie = VideoReader(testCase.MovieFile);
            testCase.verifyEqual(movie.NumFrames, testCase.Expected.movieFrames);
        end

        function ringAreaIsReportedWherePeakIsFound(testCase)
            locs = readmatrix(testCase.ResultsFile,'Sheet','Peak Locations','Range','B2');
            areas = readmatrix(testCase.ResultsFile,'Sheet','Ring Area','Range','B2');
            n = testCase.NChannels;
            testCase.verifyEqual(areas(:,1), locs(:,1), 'Frame index differs from Peak Locations');
            locCh = locs(:,2:1+n);
            areaCh = areas(:,2:1+n);
            testCase.verifyEqual(isnan(areaCh), isnan(locCh), 'Ring area should be NaN exactly where the peak is NaN');
            testCase.verifyGreaterThan(areaCh(~isnan(areaCh)), 0);
            testCase.verifyEqual(areas(2:end,2+n:1+2*n), diff(areaCh), 'AbsTol', 1e-9, ...
                'Instant columns should be the change from the previous frame');
        end

        function closingCheckBasisIsSaved(testCase)
            parameters = readcell(testCase.ResultsFile,'Sheet','parameters');
            testCase.verifyEqual(parameters{17,1}, 'closing check basis');
            testCase.verifyEqual(parameters{17,2}, 'position');
            parameters = readcell(testCase.AreaResultsFile,'Sheet','parameters');
            testCase.verifyEqual(parameters{17,2}, 'area');
        end

        function areaBasisChangesOnlyCheckpoints(testCase)
            sheets = {'Peak Intensity','Peak Locations','Halfwidths','AUCs','Percent Above Background','Ring Area'};
            for s = 1:numel(sheets)
                position = readmatrix(testCase.ResultsFile,'Sheet',sheets{s},'Range','B2');
                area = readmatrix(testCase.AreaResultsFile,'Sheet',sheets{s},'Range','B2');
                testCase.verifyEqual(area, position, 'AbsTol', 1e-9, sheets{s});
            end
            position = readmatrix(testCase.ResultsFile,'Sheet','Closing Velocity and Location','Range','C2');
            area = readmatrix(testCase.AreaResultsFile,'Sheet','Closing Velocity and Location','Range','C2');
            testCase.verifyEqual(area(1:3,:), position(1:3,:), 'AbsTol', 1e-9, ...
                'Velocity range and closing velocity should not depend on the closing check basis');
        end

        function areaBasisCheckpointsAreLabeledAndInRange(testCase)
            labels = readcell(testCase.AreaResultsFile,'Sheet','Closing Velocity and Location','Range','B2');
            values = readmatrix(testCase.AreaResultsFile,'Sheet','Closing Velocity and Location','Range','C2');
            checkpointLabels = labels(4:end,1);
            testCase.verifyNotEmpty(checkpointLabels);
            testCase.verifyTrue(all(endsWith(checkpointLabels,'(area)')), strjoin(checkpointLabels,', '));
            for c = 1:size(values,2)
                frames = values(4:end,c);
                frames = frames(~isnan(frames)); % NaN: no frame near the checkpoint
                testCase.verifyTrue(all(frames >= values(1,c) & frames <= values(2,c)), ...
                    'Checkpoint frames should lie within the velocity range');
            end
            positionLabels = readcell(testCase.ResultsFile,'Sheet','Closing Velocity and Location','Range','B2');
            testCase.verifyFalse(any(contains(positionLabels(4:end,1),'(area)')));
        end
    end
end

function setClosingCheckBasis(parametersFile, basis)
% write the closing check basis (row 17) into a parameters_post.xlsx file
parameters = readcell(parametersFile,'Sheet','parameters');
parameters(cellfun(@(x) any(ismissing(x)), parameters)) = {[]};
parameters{17,1} = 'closing check basis';
parameters{17,2} = basis;
delete(parametersFile);
writecell(parameters, parametersFile, 'Sheet', 'parameters');
end
