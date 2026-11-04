classdef testPostProcessingErrors < matlab.unittest.TestCase
    % Problems in the post-processing window are shown in dialogs (the
    % standalone app has no command window), and the window keeps working.
    % The window is opened on temporary copies of the legacy fixture and
    % driven through its control callbacks; questdlg is replaced by a stub
    % (tests/stubs) that returns a preset answer.

    properties
        TestsDir
        Template   % analyzed folder with Results_1.xlsx and movie 1, written once
    end

    methods (TestClassSetup)
        function prepareTemplate(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.TestsDir = fileparts(mfilename('fullpath'));
            repo = fullfile(testCase.TestsDir,'..');
            testCase.applyFixture(PathFixture(fullfile(repo,'src')));
            testCase.applyFixture(PathFixture(fullfile(repo,'bfmatlab')));
            testCase.applyFixture(PathFixture(fullfile(testCase.TestsDir,'stubs')));
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.Template = fullfile(tempFolder.Folder,'template');
            copyfile(fullfile(testCase.TestsDir,'fixtures','legacy_sub1'), testCase.Template);
            evalc('createNewMovie_post(testCase.Template)');
        end
    end

    methods (TestMethodTeardown)
        function closeWindows(~)
            setappdata(groot,'testQuestdlgAnswer',[]);
            delete(findall(0,'Type','figure'));
        end
    end

    methods (Test)
        function missingMovieShowsErrorAndWindowKeepsWorking(testCase)
            data = testCase.analyzedCopy('Output_A', 1);
            testCase.openWindow({data});
            moviePath = dir(fullfile(data,'sphincRedo','*_1.avi'));
            delete(fullfile(moviePath.folder, moviePath.name));
            viewer = testCase.control('Style','listbox','Image Timepoints');
            viewer.Value = 3;
            runCallback(viewer);
            message = testCase.dialogText('Viewer');
            testCase.verifySubstring(message, 'did not complete');
            viewer.Value = 1;   % the image view still works
            runCallback(viewer);
            testCase.verifyEmpty(findall(0,'Type','figure','Name','Viewer'));
        end

        function saveParametersConfirmsOrShowsError(testCase)
            data = testCase.analyzedCopy('Output_A', 1);
            testCase.openWindow({data});
            saveButton = testCase.control('Style','pushbutton','Save Parameters');
            setappdata(groot,'testQuestdlgAnswer','Save current');
            runCallback(saveButton);
            testCase.verifySubstring(testCase.dialogText('Save Post-Processing Parameters'), 'parameters_post.xlsx');
            % a folder where parameters_post.xlsx should be: the save fails with a dialog
            parametersFile = fullfile(data,'parameters_post.xlsx');
            delete(parametersFile);
            mkdir(parametersFile);
            runCallback(saveButton);
            message = testCase.dialogText('Save Post-Processing Parameters');
            testCase.verifySubstring(message, 'did not complete');
        end

        function writeAllContinuesAfterFailedMovie(testCase)
            good = testCase.analyzedCopy('Output_A', 1);
            broken = testCase.analyzedCopy('Output_B', 1);
            testCase.openWindow({good, broken});
            delete(fullfile(broken,'sphincRedo','sphinctalyzerResults.mat'));
            resultsFile = fullfile(good,'sphincRedo','Results_1.xlsx');
            before = dir(resultsFile).datenum;
            pause(1.1)   % file times have one-second resolution
            setappdata(groot,'testQuestdlgAnswer','YES');
            runCallback(testCase.control('Style','pushbutton','Write All'));
            message = testCase.dialogText('Write All Movies');
            testCase.verifySubstring(message, 'Movies written: 1 of 2');
            testCase.verifySubstring(message, 'Output_B/data_sphintest_-2channlel-sub1.tif');
            testCase.verifyGreaterThan(dir(resultsFile).datenum, before, 'The good movie should be written');
        end

        function overwriteUsesTwoDigitMovieNumber(testCase)
            data = testCase.analyzedCopy('Output_A', 12);
            testCase.openWindow({data});
            runCallback(testCase.control('Style','pushbutton','Write One'));
            runCallback(testCase.control('Style','pushbutton','Overwrite Existing'));
            choice = testCase.control('Style','radiobutton','scan movietalyzerResults_12');
            choice.Parent.SelectedObject = choice;
            runCallback(testCase.control('Style','pushbutton','Ok'));
            testCase.verifySubstring(testCase.dialogText('Write Movie'), 'Results_12.xlsx');
            testCase.verifyTrue(isfile(fullfile(data,'sphincRedo','Results_12.xlsx')));
            testCase.verifyFalse(isfile(fullfile(data,'sphincRedo','Results_2.xlsx')), 'Movie 2 should not be written');
            % same measurements as post-processing the folder directly
            direct = readmatrix(fullfile(data,'sphincRedo','Results_1.xlsx'),'Sheet','Peak Locations','Range','B2');
            fromWindow = readmatrix(fullfile(data,'sphincRedo','Results_12.xlsx'),'Sheet','Peak Locations','Range','B2');
            testCase.verifyEqual(fromWindow, direct, 'AbsTol', 1e-9);
        end
    end

    methods
        function data = analyzedCopy(testCase, outputFolder, nMovies)
            % copy of the template laid out as test_datasets/Sphincdata/<output>/data_<image>,
            % with the source image, and parameters.mat pointing at the copy
            % (nMovies > 1 lists movies 2..nMovies as existing movies)
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            datasets = fullfile(tempFolder.Folder,'test_datasets');
            data = fullfile(datasets,'Sphincdata',outputFolder,'data_sphintest_-2channlel-sub1.tif');
            mkdir(fileparts(data));
            copyfile(testCase.Template, data);
            copyfile(fullfile(testCase.TestsDir,'..','test_datasets','sphintest_-2channlel-sub1.tif'), datasets);
            load(fullfile(data,'parameters.mat'),'parameters');
            parameters.filePath = fullfile(data,'sphinc','sphinctalyzerResults.mat');
            parameters.imagePath = [datasets filesep];
            movie = fullfile(data,'sphincRedo','sphintest_-2channlel-sub1.tif_scan_movietalyzerResults_');
            parameters.moviePaths = arrayfun(@(k) sprintf('%s%d.avi', movie, k), (1:nMovies)', 'UniformOutput', false);
            save(fullfile(data,'parameters.mat'),'parameters');
        end

        function openWindow(~, folders)
            evalc('postProcessingGUI(folders)');
        end

        function h = control(testCase, property, value, label)
            h = findall(0, property, value);
            h = h(arrayfun(@(c) any(strcmp(cellstr(c.String), label)), h));
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
