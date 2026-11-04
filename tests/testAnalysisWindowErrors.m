classdef testAnalysisWindowErrors < matlab.unittest.TestCase
    % Problems in the main analysis window are shown in dialogs (the
    % standalone app has no command window), and the window's buttons are
    % not left disabled. The window is driven through its control
    % callbacks; uigetfile and questdlg are replaced by stubs (tests/stubs).

    properties
        Repo
        Work    % temporary current folder (default parameters files are saved here)
    end

    methods (TestMethodSetup)
        function openWindow(testCase)
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
            evalc('sphinctalyzerInitializerGUI');
        end
    end

    methods (Test)
        function unreadableImageShowsError(testCase)
            badImage = fullfile(testCase.Work,'not_an_image.tif');
            writelines("this is not a TIFF image", badImage);
            sphinctalyze = testCase.control('Sphinctalyze');
            enableBefore = sphinctalyze.Enable;
            setappdata(groot,'testUigetfile',{'not_an_image.tif', [testCase.Work filesep]});
            runCallback(testCase.control('Open Image(s)'));
            testCase.verifySubstring(testCase.dialogText('Open Images'), 'not_an_image.tif could not be opened');
            testCase.verifyEqual(sphinctalyze.Enable, enableBefore, 'Button states should be restored');
        end

        function parametersFileWithoutMatFileShowsError(testCase)
            writelines("speed,3", fullfile(testCase.Work,'parameters.csv'));
            setappdata(groot,'testUigetfile',{'parameters.csv', [testCase.Work filesep]});
            runCallback(testCase.control('Load Parameters'));
            message = testCase.dialogText('Load Parameters');
            testCase.verifySubstring(message, 'parameters.mat');
            testCase.verifySubstring(message, 'same folder');
        end

        function updateParametersConfirmsOrShowsError(testCase)
            testCase.openImage();
            setappdata(groot,'testQuestdlgAnswer','Proceed');
            updateButton = testCase.control('Update Parameters');
            runCallback(updateButton);
            message = testCase.dialogText('Update Common Parameters');
            testCase.verifySubstring(message, 'saved in');
            testCase.verifyTrue(isfile(fullfile(testCase.Work,'parameters.csv')));
            % a folder in place of parameters.csv: the save fails with a dialog naming the folder
            delete(fullfile(testCase.Work,'parameters.csv'));
            mkdir(fullfile(testCase.Work,'parameters.csv'));
            runCallback(updateButton);
            message = testCase.dialogText('Update Common Parameters');
            testCase.verifySubstring(message, 'could not be saved');
            % dialogs wrap long lines, so compare the folder without whitespace
            testCase.verifySubstring(regexprep(message,'\s',''), regexprep(testCase.Work,'\s',''));
        end

        function allImagesSkippedShowsSummaryAndUnlocksButtons(testCase)
            image = testCase.openImage();
            delete(image);   % the analysis cannot read it, so the image is skipped
            sphinctalyze = testCase.control('Sphinctalyze');
            runCallback(sphinctalyze);
            message = testCase.dialogText('Sphinctalyze');
            testCase.verifySubstring(message, 'Analyzed: 0 of 1');
            testCase.verifySubstring(message, 'sphintest_-2channlel-sub1.tif (path annotation)');
            testCase.verifyEqual(sphinctalyze.Enable, 'on', 'Buttons should not stay disabled');
            testCase.verifyEqual(testCase.control('Open Image(s)').Enable, 'on');
        end
    end

    methods
        function image = openImage(testCase)
            % open a copy of the test image through "Open Image(s)"
            image = fullfile(testCase.Work,'sphintest_-2channlel-sub1.tif');
            copyfile(fullfile(testCase.Repo,'test_datasets','sphintest_-2channlel-sub1.tif'), image);
            setappdata(groot,'testUigetfile',{'sphintest_-2channlel-sub1.tif', [testCase.Work filesep]});
            runCallback(testCase.control('Open Image(s)'));
            testCase.assertEmpty(findall(0,'Type','figure','Name','Open Images'), 'The test image should open');
        end

        function h = control(testCase, label)
            h = findall(0,'Type','uicontrol','String',label);
            testCase.assertNotEmpty(h, sprintf('Control "%s" not found', label));
            h = h(1);
        end

        function text = dialogText(testCase, name)
            drawnow
            dialog = findall(0,'Type','figure','Name',name);
            testCase.assertNotEmpty(dialog, sprintf('No "%s" dialog was shown', name));
            text = strjoin(string(get(findall(dialog(1),'Type','text'),'String')), ' ');
            delete(dialog);
        end
    end
end

function runCallback(h)
callback = h.Callback;
if iscell(callback)
    callback{1}(h, [], callback{2:end});
else
    callback(h, []);
end
end
