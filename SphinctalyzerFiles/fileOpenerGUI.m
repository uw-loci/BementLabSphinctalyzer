function fileOpenerGUI
    % close all other MATLAB figures, add bfmatlab toolbox for processing
    % images
    clear,clc, home, close all
    addpath(genpath(fullfile('./../bfmatlab')));

    % display GUI
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    guiCtrl = figure('Resize','off','Color',defaultBackground','Units','normalized','Position',[0.4 0.45 0.2 0.1],'Visible','on',...
        'MenuBar','none','name','Sphinctalyzer V2','NumberTitle','off');


    
    function open_file_callback(hObject, eventData)
        % If batch process is checked, uigetfile with multiselect on. 
        % Then check if fileName is a cell. If not
        % a cell, then display a message. Otherwise, create a batch directory and pass pathName and
        % cellName into load_image
        % 
        % Else, uigetfile with multiselect off. Pass pathName and
        % {fileName}
        % and ''
        % into load_image
        % 
    end

    function load_image(pathName, fileNames, batchDirectory)
        % create an object array of length fileNames, with default values
        % for file in fileNames
        % - instantiate object
        % - load BF params into that object
        % - add it into the object array
        % pass object array into sphinctalyzeInitializeGUI(objarray)
    end
end