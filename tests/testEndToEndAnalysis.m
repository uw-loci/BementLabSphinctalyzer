classdef testEndToEndAnalysis < matlab.unittest.TestCase
    % End-to-end analysis in the main window, as a user runs it:
    % Load Parameters -> Open Image(s) -> Sphinctalyze -> results.
    % The wound outline drawn by hand for this image (fixtures/e2e_sub1) is
    % reused, so no drawing is needed; uigetfile and questdlg are stubbed
    % (tests/stubs, "Reuse Saved Path"). The results are compared with the
    % analysis run by hand (fixtures/e2e_sub1_expected.mat, recorded with
    % fixtures/make_e2e_expected.m).

    properties (Constant)
        ImageName = 'sphintest_-2channlel-sub1.tif'
        OutlineName = 'SavedPath_sphintest_-2channlel-sub1_ref_[CH1]_framePosition_[2].mat'
        TimeoutSeconds = 180
    end

    properties
        Expected
        ResultsFile
        TimedOut = ''   % names of the open windows if the run had to be stopped
    end

    methods (TestClassSetup)
        function runAnalysis(testCase)
            import matlab.unittest.fixtures.PathFixture
            testsDir = fileparts(mfilename('fullpath'));
            repo = fullfile(testsDir,'..');
            fixture = fullfile(testsDir,'fixtures','e2e_sub1');
            testCase.applyFixture(PathFixture(fullfile(repo,'src')));
            testCase.applyFixture(PathFixture(fullfile(repo,'bfmatlab')));
            testCase.applyFixture(PathFixture(fullfile(testsDir,'stubs')));
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(tempFolder.Folder));
            testCase.addTeardown(@() delete(findall(0,'Type','figure')));
            testCase.addTeardown(@() setappdata(groot,'testUigetfile',[]));
            testCase.addTeardown(@() setappdata(groot,'testQuestdlgAnswer',[]));
            loaded = load(fullfile(testsDir,'fixtures','e2e_sub1_expected.mat'),'expected');
            testCase.Expected = loaded.expected;

            % image with its saved outline, and the parameters of the run by hand
            images = fullfile(tempFolder.Folder,'images');
            params = fullfile(tempFolder.Folder,'params');
            mkdir(fullfile(images,'Sphincdata','savedPath'));
            mkdir(params);
            copyfile(fullfile(repo,'test_datasets',testCase.ImageName), images);
            copyfile(fullfile(fixture,testCase.OutlineName), fullfile(images,'Sphincdata','savedPath'));
            copyfile(fullfile(fixture,'parameters.csv'), params);
            copyfile(fullfile(fixture,'parameters.mat'), params);

            evalc('sphinctalyzerInitializerGUI');
            setappdata(groot,'testUigetfile',{'parameters.csv', [params filesep]});
            press('Load Parameters');
            delete(findall(0,'Type','figure','-not','Tag','mainGUI','-not','Name',''));   % "Parameters successfully loaded."
            setappdata(groot,'testUigetfile',{testCase.ImageName, [images filesep]});
            press('Open Image(s)');
            setappdata(groot,'testQuestdlgAnswer','Reuse Saved Path');

            % if a prompt the test does not answer appears, stop the run
            guard = timer('StartDelay', testCase.TimeoutSeconds, 'TimerFcn', @(~,~) stopRun(testCase));
            testCase.addTeardown(@() delete(guard));
            start(guard);
            evalc('press(''Sphinctalyze'')');
            stop(guard);

            results = dir(fullfile(images,'Sphincdata','Output_*','*','sphincRedo','Results_1.xlsx'));
            testCase.assertEqual(testCase.TimedOut, '', ...
                sprintf('The analysis did not finish within %d s; open windows: %s', testCase.TimeoutSeconds, testCase.TimedOut));
            testCase.assertNumElements(results, 1, 'One Results_1.xlsx should be written');
            testCase.ResultsFile = fullfile(results.folder, results.name);
        end
    end

    methods (Test)
        function measurementsMatchRunByHand(testCase)
            names = fieldnames(testCase.Expected.sheets);
            sheets = {'Peak Intensity','Peak Locations','Halfwidths','AUCs','Percent Above Background','Ring Area'};
            for s = 1:numel(sheets)
                actual = readmatrix(testCase.ResultsFile,'Sheet',sheets{s},'Range','B2');
                testCase.verifyEqual(actual, testCase.Expected.sheets.(names{s}), 'AbsTol', 1e-9, sheets{s});
            end
        end

        function closingSheetMatchesRunByHand(testCase)
            actual = readcell(testCase.ResultsFile,'Sheet','Closing Velocity and Location','Range','B2');
            testCase.verifyTrue(isequaln(actual, testCase.Expected.closing), ...
                'Closing velocity and checkpoint labels and values should match the run by hand');
        end

        function parametersAreSaved(testCase)
            parameters = readcell(testCase.ResultsFile,'Sheet','parameters');
            testCase.verifyEqual(parameters{8,2}, testCase.Expected.xMinStepMax);
            testCase.verifyEqual(parameters(16,2:3), testCase.Expected.channelNames);
            testCase.verifyEqual(parameters{17,2}, testCase.Expected.closingCheckBasis);
        end

        function movieHasAllFrames(testCase)
            movies = dir(fullfile(fileparts(testCase.ResultsFile),'*_scan_movietalyzerResults_1.avi'));
            testCase.assertNumElements(movies, 1);
            movie = VideoReader(fullfile(movies.folder, movies.name));
            testCase.verifyEqual(movie.NumFrames, testCase.Expected.movieFrames);
        end

        function windowsAreReadyAfterTheRun(testCase)
            testCase.verifyNotEmpty(findall(0,'Type','figure','Name','Sphinctalyzer: Results'), 'The results window should open');
            testCase.verifyEmpty(findall(0,'Type','figure','-regexp','Name','^Annotating'), 'No drawing window should be left open');
            sphinctalyze = findall(0,'Type','uicontrol','String','Sphinctalyze');
            testCase.verifyEqual(sphinctalyze.Enable, 'on', 'The main window buttons should be enabled again');
        end
    end
end

function press(label)
% press a button of the main window through its callback
button = findall(0,'Type','uicontrol','String',label);
callback = button(1).Callback;
if iscell(callback)
    callback{1}(button(1), [], callback{2:end});
else
    callback(button(1), []);
end
end

function stopRun(testCase)
% record the open windows and release any window waiting for input
figures = findall(0,'Type','figure');
testCase.TimedOut = strjoin(string(get(figures,'Name')), ' | ');
for f = figures'
    uiresume(f);
end
delete(figures(~strcmp(get(figures,'Tag'),'mainGUI')));
end
