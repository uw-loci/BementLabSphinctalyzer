function fileOpenerGUI
    % close all other MATLAB figures, add bfmatlab toolbox for processing
    % images
    clear,clc, home, close all
    addpath(genpath(fullfile('./../bfmatlab')));

    % display GUI
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    guiCtrl = figure('Resize','off', ...
        'Color',defaultBackground', ...
        'Units','normalized', ...
        'Position',[0.4 0.45 0.2 0.1], ...
        'Visible','on',...
        'MenuBar','none', ...
        'name','Sphinctalyzer V2', ...
        'NumberTitle','off');
    
    % Panel for batch processing and single image processing
    processingOptionsPanel = uipanel('Parent',guiCtrl, ...
        'visible','on', ...
        'BorderType','none', ...
        'FontSize',12, ...
        'Units','normalized', ...
        'Position',[0 0.35 1 0.55]0);

    % Create radio button group for batch processing and single image
    % processing, so the user can't select both of them at once.
    processingOptions = uibuttongroup('parent',processingOptionsPanel, ...
        'title','Processing Options', ...
        'visible','on', ...
        'FontSize',12, ...
        'Units','normalized', ...
        'Position',[0 0 1 1]);
    singeImageProcessing = uicontrol('Style','radiobutton','String','Single Image','Units','normalized',...
        'pos',[0 0.5 0.5 0.5 ],'parent',processingOptions,'HandleVisibility','on','FontSize',10,'Enable','on');
    batchImageProcessing = uicontrol('Style','radiobutton','String','Batch','Units','normalized',...
        'pos',[0 0 0.5 0.5],'parent',processingOptions,'HandleVisibility','on','FontSize',10,'Enable','on');

    % Create Open image(s) button
    openImage = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Open Image(s)',...
        'FontSize',12, ...
        'Enable','on', ...
        'Units','normalized', ...
        'Position',[0.2 0.025 0.6 0.3],...
        'Callback', {@open_file_callback});
    
    function open_file_callback(hObject, eventData)
        % Check if user selected batch
        if strcmp(get(get(processingOptions,'SelectedObject'),'String'),'Batch')
            % User selected batch
            % Open uigetfile interface for the user to select multiple images
            [imageName, imagePath] = uigetfile({'*.tif;*.tiff;'},'MultiSelect','on');
             if isequal(imageName,0)
                 % User selected cancel
                 return;
             elseif ~iscell(imageName)
                 % User selected only one file
                 errordlg('Please select at least two image files', 'File Error')
                 return;
             else
                 % User selected multiple images, so create a batch
                 % directory and pass the pathName, fileName, and
                 % batchDirectory into the load_image function
                 currDate = strrep(datestr(datetime), '-', '_');
                 batchDirectory = strcat('../Sphincdata/batch_',currDate);
                 mkdir (batchDirectory)
                 load_image(imageName,imagePath,batchDirectory)
             end
        else
            % User selected single image
            [imageName, imagePath] = uigetfile({'*.tif;*.tiff;'},'MultiSelect','on');
            if isequal(imageName,0)
                % User selected cancel
                return;
            else
                % User selected an image, so set batch directory to an
                % empty string and pass the pathName,fileNAme ,and
                % bathDirectroy into the load_image function
                batchDirectory = '';
                load_image({imageName},imagePath,batchDirectory)
            end
        end
    end

    function load_image(imageNames, imagePath, batchDirectory)
        % create an object array of length fileNames, with default values
        objarray(1:length(imageNames)) = Image(0,1,0,3,1,1,3,0,8,0,0, ...
            'gray',6,{'Distance (pixels) from wound center','Normalized Gray Value'}, ...
            [-150 50 0],[-0.1 0.3 1.1],1,1,imagePath,0,0, ...
            {[1 0 0],[0 .6 0],[0 0 1]},0,'NorthWest',1,batchDirectory);
        % for obj in objarray
        for i = 1:length(objarray)
            % add image file name to the obj
            objarray(i).imageName = imageNames{i};
            ff = fullfile(imagePath,objarray(i).imageName);
            r = bfGetReader(ff);
            nChannels = r.getSizeC(); 
            nTimepoints = r.getSizeT(); 
            % Add nChannels, nTimepoints, and timepointEnd to the obj
            objarray(i).nChannels = nChannels;
            if nChannels == 1
                objarray(i).loadMulti = 0;
            end
            objarray(i).nTimepoints = nTimepoints;
            objarray(i).timepointEnd = nTimepoints;
            cellArray = cell(nChannels, 3);
            % Create cell array
            for j = 1:nChannels
                for k = 1:3
                    if k == 1
                        cellArray{j,k} = strcat('channel', num2str(j));
                    elseif k == 2
                        cellArray{j,k} = 1;
                    else
                        if j == 1
                            cellArray{j,k} = 1;
                        else
                            cellArray{j,k} = 0;
                        end
                    end
                end
            end
            % pass cellarray into the object
            objarray(i).cellArray = cellArray;
            % from cell array, add channelNames into the object
            objarray(i).channelNames = {cellArray{:, 1}};
        end
        % pass the object array into sphinctalyzeInitialize GUI
        delete(guiCtrl)
        sphinctalyzerInitializerGUI(objarray)
    end
end