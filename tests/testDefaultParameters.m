classdef testDefaultParameters < matlab.unittest.TestCase
    % The default parameters files shipped with the standalone app
    % (writeDefaultParameters) can be loaded with "Load Parameters" and give
    % the same settings as opening an image without a parameters file. The
    % settings are compared through the parameters.csv that "Update
    % Parameters" saves for the open image. uigetfile and questdlg are
    % replaced by stubs (tests/stubs).

    properties (Constant)
        ImageName = 'sphintest_-2channlel-sub1.tif'
    end

    properties
        Repo
        Work    % temporary current folder ("Update Parameters" saves here)
    end

    methods (TestMethodSetup)
        function setUp(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.Repo = fullfile(fileparts(mfilename('fullpath')),'..');
            testCase.applyFixture(PathFixture(fullfile(testCase.Repo,'src')));
            testCase.applyFixture(PathFixture(fullfile(testCase.Repo,'bfmatlab')));
            testCase.applyFixture(PathFixture(fullfile(testCase.Repo,'tests','stubs')));
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.Work = tempFolder.Folder;
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(testCase.Work));
            testCase.addTeardown(@() delete(findall(0,'Type','figure')));
            testCase.addTeardown(@() setappdata(groot,'testUigetfile',[]));
            testCase.addTeardown(@() setappdata(groot,'testQuestdlgAnswer',[]));
            copyfile(fullfile(testCase.Repo,'test_datasets',testCase.ImageName), testCase.Work);
        end
    end

    methods (Test)
        function filesHoldTheBuiltInDefaults(testCase)
            folder = fullfile(testCase.Work,'defaults');
            mkdir(folder);
            evalc('writeDefaultParameters(folder)');
            csv = readcell(fullfile(folder,'parameters.csv'));
            testCase.verifyEqual(setting(csv,'timepointStart'), -1);
            testCase.verifyEqual(setting(csv,'timepointEnd'), -1);
            testCase.verifyEqual(setting(csv,'xMinStepMax'), '[0 10 30]');
            testCase.verifyEqual(setting(csv,'micronsPerPixel'), 0.192);
            testCase.verifyEqual(setting(csv,'channelNames',1:3), {'channel1','channel2','channel3'});
            saved = load(fullfile(folder,'parameters.mat'));
            testCase.verifyClass(saved.parameters, 'Image');
        end

        function loadingDefaultsMatchesNoParametersFile(testCase)
            withoutFile = testCase.settingsAfterOpening('');
            folder = fullfile(testCase.Work,'defaults');
            mkdir(folder);
            evalc('writeDefaultParameters(folder)');
            withDefaults = testCase.settingsAfterOpening(folder);
            % each window names its own output folder (Output_<date_time>)
            perWindow = @(csv) csv(~strcmp(csv(:,1),'batchDirectory'), :);
            testCase.verifyEqual(perWindow(withDefaults), perWindow(withoutFile));
            % all frames of the image are analyzed
            testCase.verifyEqual(setting(withDefaults,'timepointStart'), 1);
            testCase.verifyEqual(setting(withDefaults,'timepointEnd'), setting(withDefaults,'nTimepoints'));
        end
    end

    methods
        function csv = settingsAfterOpening(testCase, parametersFolder)
            % open the test image in a new main window, loading parameters.csv
            % from parametersFolder first unless it is empty, and return the
            % settings that "Update Parameters" saves for the image
            delete(findall(0,'Type','figure'));
            evalc('sphinctalyzerInitializerGUI');
            if ~isempty(parametersFolder)
                setappdata(groot,'testUigetfile',{'parameters.csv', [parametersFolder filesep]});
                evalc('press(''Load Parameters'')');
                % the button is disabled once a parameters file is loaded
                loadButton = findall(0,'Type','uicontrol','String','Load Parameters');
                dialogs = findall(0,'Type','figure','-not','Tag','mainGUI');
                testCase.assertEqual(loadButton(1).Enable, 'off', ...
                    sprintf('The parameters should load; open dialogs: %s', strjoin(string(get(findall(dialogs,'Type','text'),'String')), ' | ')));
            end
            setappdata(groot,'testUigetfile',{testCase.ImageName, [testCase.Work filesep]});
            evalc('press(''Open Image(s)'')');
            testCase.assertEmpty(findall(0,'Type','figure','Name','Open Images'), 'The test image should open');
            setappdata(groot,'testQuestdlgAnswer','Proceed');
            evalc('press(''Update Parameters'')');
            csv = readcell(fullfile(testCase.Work,'parameters.csv'));
            delete(fullfile(testCase.Work,'parameters.*'));
        end
    end
end

function value = setting(csv, name, columns)
% value of a setting in a parameters.csv read with readcell: the first
% value, or the cells in the given value columns
values = csv(strcmp(csv(:,1),name), 2:end);
if nargin < 3
    value = values{1};
else
    value = values(columns);
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
