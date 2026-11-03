classdef testLegacyPostProcessing < matlab.unittest.TestCase
    % Regression test: data analyzed by earlier versions (saved with a
    % negative x axis, e.g. [-28.8 9.6 0]) can still be post-processed, and
    % the output uses positive distances from wound center.
    %
    % fixtures/legacy_sub1 is an analyzed folder from an earlier version.
    % fixtures/legacy_sub1_expected.mat holds the Results_1.xlsx values the
    % code produced on it before the positive x axis change (commit bda1fe0).

    properties
        Expected
        ResultsFile
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
    end
end
