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
            setappdata(groot,'testQuestdlgQuestion',[]);
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
            saved = readcell(fullfile(data,'parameters_post.xlsx'),'Sheet','parameters');
            testCase.verifyEqual(saved(18,1:2), {'movie font size', getDefaultMovieFontSize()});
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
            setappdata(groot,'testQuestdlgAnswer','Overwrite Results_1');
            runCallback(testCase.control('Style','pushbutton','Write All'));
            message = testCase.dialogText('Write All Movies');
            testCase.verifySubstring(message, 'Movies written: 1 of 2');
            testCase.verifySubstring(message, 'Output_B/data_sphintest_-2channlel-sub1.tif');
            testCase.verifyGreaterThan(dir(resultsFile).datenum, before, 'The good movie should be written');
        end

        function writeAllCreatesNewResults(testCase)
            % folder A already has Results_1 and Results_2, folder B only Results_1
            folderA = testCase.analyzedCopy('Output_A', 2);
            evalc('createNewMovie_post(folderA, 2)');
            folderB = testCase.analyzedCopy('Output_B', 1);
            testCase.openWindow({folderA, folderB});
            firstResults = {fullfile(folderA,'sphincRedo','Results_1.xlsx'), fullfile(folderB,'sphincRedo','Results_1.xlsx')};
            before = cellfun(@(f) dir(f).datenum, firstResults);
            pause(1.1)   % file times have one-second resolution
            setappdata(groot,'testQuestdlgAnswer','Create New');
            runCallback(testCase.control('Style','pushbutton','Write All'));
            % the question names each folder's new results
            question = strjoin(string(getappdata(groot,'testQuestdlgQuestion')), ' ');
            testCase.verifySubstring(question, 'Output_A/data_sphintest_-2channlel-sub1.tif: Results_3');
            testCase.verifySubstring(question, 'Output_B/data_sphintest_-2channlel-sub1.tif: Results_2');
            message = testCase.dialogText('Write All Movies');
            testCase.verifySubstring(message, 'Movies written: 2 of 2');
            testCase.verifySubstring(message, 'Output_A/data_sphintest_-2channlel-sub1.tif: Results_3');
            testCase.verifySubstring(message, 'Output_B/data_sphintest_-2channlel-sub1.tif: Results_2');
            movie = 'sphintest_-2channlel-sub1.tif_scan_movietalyzerResults_';
            testCase.verifyTrue(isfile(fullfile(folderA,'sphincRedo','Results_3.xlsx')));
            testCase.verifyTrue(isfile(fullfile(folderA,'sphincRedo',[movie '3.avi'])));
            testCase.verifyTrue(isfile(fullfile(folderB,'sphincRedo','Results_2.xlsx')));
            testCase.verifyTrue(isfile(fullfile(folderB,'sphincRedo',[movie '2.avi'])));
            testCase.verifyEqual(cellfun(@(f) dir(f).datenum, firstResults), before, 'Results_1 should not be overwritten');
            % the current image's new movie is listed in the viewer
            viewer = findall(0,'Type','uicontrol','Style','listbox');
            viewer = viewer(arrayfun(@(c) any(strcmp(cellstr(c.String),'Circle Scan')), viewer));
            testCase.verifyTrue(any(strcmp(cellstr(viewer(1).String), 'scan movietalyzerResults_3')));
        end

        function writeAllCancelWritesNothing(testCase)
            data = testCase.analyzedCopy('Output_A', 1);
            testCase.openWindow({data});
            setappdata(groot,'testQuestdlgAnswer','Cancel');
            runCallback(testCase.control('Style','pushbutton','Write All'));
            testCase.verifyEmpty(findall(0,'Type','figure','Name','Write All Movies'));
            testCase.verifyFalse(isfile(fullfile(data,'sphincRedo','Results_2.xlsx')));
        end

        function nextResultsIndexCountsResultsAndMovies(testCase)
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            folder = tempFolder.Folder;
            testCase.verifyEqual(nextResultsIndex(folder), 1, 'No sphincRedo folder');
            mkdir(fullfile(folder,'sphincRedo'));
            testCase.verifyEqual(nextResultsIndex(folder), 1, 'Empty sphincRedo folder');
            writelines("x", fullfile(folder,'sphincRedo','Results_2.xlsx'));
            testCase.verifyEqual(nextResultsIndex(folder), 3);
            writelines("x", fullfile(folder,'sphincRedo','img.tif_scan_movietalyzerResults_4.avi'));
            testCase.verifyEqual(nextResultsIndex(folder), 5);
            writelines("x", fullfile(folder,'sphincRedo','._Results_9.xlsx'));
            testCase.verifyEqual(nextResultsIndex(folder), 5, 'macOS "._" files are ignored');
        end

        function cleanUpThisMovieDeletesExtraResults(testCase)
            data = testCase.analyzedCopy('Output_A', 3);
            evalc('createNewMovie_post(data, 2)');
            evalc('createNewMovie_post(data, 3)');
            redo = fullfile(data,'sphincRedo');
            writelines("plot", fullfile(redo,'Results_2_AUCs.tif'));
            % settings saved for a later run differ from those of Results_1
            setPostParameter(fullfile(data,'parameters_post.xlsx'), 18, 'movie font size', 30);
            testCase.openWindow({data});
            setappdata(groot,'testQuestdlgAnswer','Delete');
            runCallback(testCase.control('Style','pushbutton','Clean Up This Movie'));
            question = strjoin(string(getappdata(groot,'testQuestdlgQuestion')), ' ');
            testCase.verifySubstring(question, 'Output_A/data_sphintest_-2channlel-sub1.tif: Results_2, Results_3 (5 files)');
            testCase.verifySubstring(testCase.dialogText('Clean Up Results'), 'Deleted 5 files in 1 folder.');
            remaining = sort({dir(redo).name});
            remaining = remaining(~startsWith(remaining,'.'));
            testCase.verifyEqual(remaining, sort({'Results_1.xlsx','sphinctalyzerResults.mat', ...
                'sphintest_-2channlel-sub1.tif_scan_movietalyzerResults_1.avi'}));
            testCase.verifyTrue(isfile(fullfile(data,'parameters_post.xlsx')));
            % parameters_post.xlsx now holds the settings of Results_1
            post = readcell(fullfile(data,'parameters_post.xlsx'),'Sheet','parameters');
            first = readcell(fullfile(redo,'Results_1.xlsx'),'Sheet','parameters');
            testCase.verifyEqual(post(:,1:2), first(:,1:2));
            testCase.verifyEqual(post{18,2}, getDefaultMovieFontSize());
            % the movie list shows only Results_1
            viewer = findall(0,'Type','uicontrol','Style','listbox');
            viewer = viewer(arrayfun(@(c) any(strcmp(cellstr(c.String),'Circle Scan')), viewer));
            testCase.verifyEqual(cellstr(viewer(1).String)', {'Image Timepoints','Circle Scan','scan movietalyzerResults_1'});
        end

        function cleanUpCancelDeletesNothing(testCase)
            data = testCase.analyzedCopy('Output_A', 2);
            evalc('createNewMovie_post(data, 2)');
            testCase.openWindow({data});
            setappdata(groot,'testQuestdlgAnswer','Cancel');
            runCallback(testCase.control('Style','pushbutton','Clean Up This Movie'));
            testCase.verifyEmpty(findall(0,'Type','figure','Name','Clean Up Results'));
            testCase.verifyTrue(isfile(fullfile(data,'sphincRedo','Results_2.xlsx')));
        end

        function cleanUpAllMoviesCleansEveryFolder(testCase)
            folderA = testCase.analyzedCopy('Output_A', 2);
            evalc('createNewMovie_post(folderA, 2)');
            folderB = testCase.analyzedCopy('Output_B', 2);
            evalc('createNewMovie_post(folderB, 2)');
            testCase.openWindow({folderA, folderB});
            setappdata(groot,'testQuestdlgAnswer','Delete');
            runCallback(testCase.control('Style','pushbutton','Clean Up All Movies'));
            testCase.verifySubstring(testCase.dialogText('Clean Up Results'), 'Deleted 4 files in 2 folders');
            for folder = {folderA, folderB}
                testCase.verifyFalse(isfile(fullfile(folder{1},'sphincRedo','Results_2.xlsx')));
                testCase.verifyTrue(isfile(fullfile(folder{1},'sphincRedo','Results_1.xlsx')));
            end
        end

        function extraResultsFilesListsOnlyLaterResults(testCase)
            tempFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            redo = fullfile(tempFolder.Folder,'sphincRedo');
            mkdir(redo);
            names = {'Results_1.xlsx','img.tif_scan_movietalyzerResults_1.avi','Results_1_AUCs.tif', ...
                'Results_2.xlsx','._Results_2.xlsx','img.tif_scan_movietalyzerResults_12.avi','Results_12_Halfwidths.tif', ...
                'sphinctalyzerResults.mat','notes_2.xlsx'};
            for i = 1:numel(names)
                writelines("x", fullfile(redo,names{i}));
            end
            [files, numbers] = extraResultsFiles(tempFolder.Folder);
            [~, listed, ext] = fileparts(files);
            testCase.verifyEqual(sort(strcat(listed, ext))', sort({'Results_2.xlsx','._Results_2.xlsx', ...
                'img.tif_scan_movietalyzerResults_12.avi','Results_12_Halfwidths.tif'}));
            testCase.verifyEqual(numbers, [2 12]);
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

function setPostParameter(parametersFile, row, name, value)
% write one post-processing parameter (name and value in a row) into a
% parameters_post.xlsx file
parameters = readcell(parametersFile,'Sheet','parameters');
parameters(cellfun(@(x) any(ismissing(x)), parameters)) = {[]};
parameters{row,1} = name;
parameters{row,2} = value;
delete(parametersFile);
writecell(parameters, parametersFile, 'Sheet', 'parameters');
end
