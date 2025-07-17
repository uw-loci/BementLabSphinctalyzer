function sphinctalyzerInitializerGUI
    % display GUI with:
    % - cell inputs table
    % - slice options
    % - sphinctalyzer parameters
    % - roi options
    % - colormap options
    % - image queue
    % - stack previewer for the queue
    % dialogue box for exceptions?
    % - "Sphinctalyze All" and cancel buttons
    % update_parameters(1) load parameters for the first image
    % mcc -v -m sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer 0.2.0 MAC(intel 64-bit) standalone built on 09/19/2023..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.0, version = 0.2.0' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer 0.2.0 MAC(intel 64-bit) standalone built on 09/19/2023..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.1, version = 0.2.1' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer 0.2.1 MAC(intel 64-bit) standalone built on 11/03/2023..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.2, version = 0.2.2' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer 0.2.2 MAC(intel 64-bit) standalone built on 12/07/2023..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.3, version = 0.2.3' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer 0.2.3 MAC(intel 64-bit) standalone built on 12/18/2023..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.4 Beta2, version = 0.2.4 Beta2' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.4 Beta2 MAC(intel 64-bit) standalone built on 04/23/2024..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.4 Beta3, version = 0.2.4 Beta3' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.4 Beta3 MAC(intel 64-bit) standalone built on 08/26/2024..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.5 Beta1, version = 0.2.5 Beta1' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.5 Beta1 Windows(intel 64-bit) standalone built on 11/20/2024..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.5 Beta1, version = 0.2.5 Beta1' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.5 Beta1 Mac(intel 64-bit) standalone built on 11/20/2024..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.6 Beta1, version = 0.2.6 Beta1' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.6 Beta1 Mac(intel 64-bit) standalone built on 01/17/2025..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.6 Beta2, version = 0.2.6 Beta1' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.6 Beta1 Mac(intel 64-bit) standalone built on 02/02/2025..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.7 Beta1, version = 0.2.7 Beta1' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.7 Beta1 Mac(intel 64-bit) standalone built on 03/14/2025..."'
    % mcc -v -W 'main:Sphinctalyzer0.2.7 Beta2, version = 0.2.7 Beta2' sphinctalyzerInitializerGUI.m -a ./ -R '-startmsg, "Launching Sphinctalyzer v0.2.7 Beta2 Mac(intel 64-bit) standalone built on 06/04/2025..."'

    clc, home
    openningWindows= findobj(0,'Type', 'Figure');
    if ~isempty(openningWindows)
        delete(openningWindows)
    end
    objarray = [];
     % initialize GUI parameters for the first image
    currentObj = 1;
    loadParameters = 0;
    parameterFileName = '';
    parameterFilePath = pwd;
    imageName = '';
    imagePath = pwd;
    outputPath = pwd;


    if ~isdeployed
        addpath(genpath(fullfile('./../bfmatlab')));
    end
    screenWH = get(0,'screensize');
    screenWidth = screenWH(3);

    % Display GUI
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    guiCtrl = figure('Resize','on', ...
        'Color',defaultBackground', ...
        'Units','normalized', ...
        'Position',[0.10 0.10 0.85 0.85], ...
        'Visible','on',...
        'MenuBar','none', ...
        'name','Sphinctalyzer v0.2.7 Beta2: Analysis', ...
        'Tag', 'mainGUI',...
        'NumberTitle','off');
    
    % Keep Analysis Window open
    keepAnalysisOpen = uicontrol('Parent', guiCtrl, ...
        'Style','checkbox', ...
        'String','Keep This Window Open', ...
        'FontSize', 11, ...
        'Enable', 'off', ...
        'Value', 1, ...
        'Units', 'normalized', ...
        'Position', [0.67 0 0.2 0.05]);

    % Open File(s) button
    openFile = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Open Image(s)',...
        'FontSize',11, ...
        'Enable','on', ...
        'Units','normalized', ...
        'Position',[0.15 0.91 0.12 0.08],...
        'Callback', {@open_file_callback});

    % Load parameters button
    loadParam = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Load Parameters',...
        'FontSize',11, ...
        'Enable','on', ...
        'Units','normalized', ...
        'Position',[0.01 0.91 0.12 0.08],...
        'Tooltip','Select a parameter.csv file for the subsequently loaded image(s)',...
        'Callback', {@load_param_callback});

    % Post processing button
    postProcess = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Post Process',...
        'FontSize',11, ...
        'Enable','on', ...
        'Units','normalized', ...
        'Position',[0.29 0.91 0.12 0.08],...
        'Tooltip','Select the output folder of an image to start a post-processing',...
        'Callback', {@post_process_callback});

    % cell inputs panel
    cellInputsPanel = uipanel('Parent',guiCtrl, ...
        'Title','Cell Inputs Table', ...
        'FontSize',12, ...
        'Units','normalized', ...
        'Position',[0.01 0.679 0.4 0.22]);
    
    cellInputs = uitable('Parent',cellInputsPanel, ...
        'ColumnName',{'Display Frame', 'Is Reference?'}, ...
        'ColumnFormat',{'Numeric','Logical'},...
        'RowName', {'Channel Name'},...
        'Data', {1,'False'},...
        'ColumnEditable',true,...
        'Units','normalized', ...
        'Position',[0.01 0.0975 0.69 0.805], ...
        'Enable','off', ...
        'CellEditCallback',{@cell_inputs_callback});

    tableWidth = round(screenWidth*guiCtrl.Position(3)*cellInputsPanel.Position(3)*cellInputs.Position(3));
    cellInputs.ColumnWidth = {round(tableWidth*0.30),round(tableWidth*0.30)};

    changeChannelNames = uicontrol('Parent',cellInputsPanel, ...
        'Style','pushbutton', ...
        'String','Change Channel Names', ...
        'Enable','off', ...
        'FontSize',10,...
        'Units','normalized', ...
        'Position',[0.70 0.5075 0.290 0.395], ...
        'callback',{@prompt_names});

    changeVelocityRange = uicontrol('Parent',cellInputsPanel, ...
        'Style','pushbutton', ...
        'String','Change Velocity Range', ...
        'Enable','off', ...
        'FontSize',10,...
        'Units','normalized', ...
        'Position',[0.70 0.0975 0.290 0.395], ...
        'callback',{@velocity_range});

    % slice options panel
    slicesPanel = uipanel('Parent',guiCtrl, ...
        'visible','on', ...
        'BorderType','none', ...
        'Units','normalized', ...
        'Position',[0.01 0.539 0.4 .13]);
    
    hsr = uibuttongroup('parent',slicesPanel, ...
        'title','Slices Range', ...
        'visible','on', ...
        'FontSize',12, ...
        'Units','normalized', ...
        'Position',[0 0 1 1]);
    % Create two radio buttons in the button group and edit fields for
    % slice ranges
    sru1 = uicontrol('Style','radiobutton', ...
        'String','Whole stack', ...
        'Units','normalized',...
        'pos',[0 0.5 0.5 0.4], ...
        'parent',hsr, ...
        'HandleVisibility','on', ...
        'FontSize',10, ...
        'Enable','off');
    sru2 = uicontrol('Style','radiobutton', ...
        'String','Slices', ...
        'Units','normalized',...
        'pos',[0 0.1 0.5 0.4], ...
        'parent',hsr, ...
        'HandleVisibility','on', ...
        'FontSize',10,'Enable','off');
    sru3 = uicontrol('Style','edit', ...
        'String','', ...
        'Units','normalized',...
        'pos',[0.25 0.1 0.1 0.4], ...
        'parent',hsr, ...
        'HandleVisibility','on', ...
        'Enable','off', ...
        'BackgroundColor','w',...
        'Userdata',[], ...
        'Callback',{@get_textbox_sru3});
    sru4 = uicontrol('Style','text', ...
        'String','To', ...
        'Units', ...
        'normalized',...
        'pos',[ 0.40 -0.05 0.1 0.4], ...
        'parent',hsr, ...
        'HandleVisibility','on', ...
        'Enable','off', ...
        'FontSize',10);
    sru5 = uicontrol('Style','edit', ...
        'String','', ...
        'Units','normalized',...
        'pos',[0.55 0.1 0.1 0.4], ...
        'parent',hsr, ...
        'HandleVisibility','on', ...
        'Enable','off', ...
        'BackgroundColor','w',...
        'Userdata',[], ...
        'Callback',{@get_textbox_sru5});
    set(hsr,'SelectionChangeFcn',@slice_selection_changed);

    % sphinctalyzer parameters panel
    sphinctalyzerParametersPanel = uipanel('Parent',guiCtrl, ...
        'Title','Sphinctalyzer Parameters', ...
        'Units','normalized', ...
        'FontSize',12, ...
        'Position',[0.01 0.129 0.15 .4]);
    speedLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','inspeed and outspeed', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 0.88 .75 .11]);
    enterSpeed = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','3', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',3, ...
        'Units','normalized', ...
        'Position',[0.75 0.89 .24 .11], ...
        'Callback',{@get_textbox_speed}, ...
        'Enable','off');
    shapeLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Scan Shape', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 .76 .75 .11]);
    enterShape = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[0.75 .77 .24 .11], ...
        'Callback',{@get_textbox_shape}, ...
        'Enable','off');   
    detectionLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Detection Method', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 .64 .75 .11]);
    enterDetection = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit',['' ...
        'String'],'3', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',3, ...
        'Units','normalized', ...
        'Position',[.75 .65 .24 .11], ...
        'Callback',{@get_textbox_detection}, ...
        'Enable','off');    
    smoothLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Smooth Number', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 .52 .75 .11]);
    enterSmooth = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','0', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',0, ...
        'Units','normalized', ...
        'Position',[.75 .53 .24 .11], ...
        'Callback',{@get_textbox_smooth}, ...
        'Enable','off');    
    stepLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Step', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 .40 .75 .11]);
    enterStep = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','8', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',8, ...
        'Units','normalized', ...
        'Position',[.75 .41 .24 .11], ...
        'Callback',{@get_textbox_step}, ...
        'Enable','off');
    normalizationLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Normalization', ...
        'FontSize',10, ...
        'Units', 'normalized', ...
        'Position',[0 .28 .75 .11]);
    enterNormalization = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[.75 .29 .24 .11], ...
        'Callback',{@get_textbox_normalization}, ...
        'Enable','off');
    micronsPerPixelLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Microns Per Pixel', ...
        'FontSize',10, ...
        'Units', 'normalized', ...
        'Position',[0 .16 .75 .11]);
    enterMicronsPerPixel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[.75 .17 .24 .11], ...
        'Callback',{@get_textbox_micronsPerPixel}, ...
        'Enable','off');
    timePerFrameLabel = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','text', ...
        'String','Time Per Frame', ...
        'FontSize',10, ...
        'Units', 'normalized', ...
        'Position',[0 0.04 .75 .11]);
    entertimePerFrame = uicontrol('Parent',sphinctalyzerParametersPanel, ...
        'Style','edit', ...
        'String','6', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',6, ...
        'Units','normalized', ...
        'Position',[.75 0.05 .24 .11], ...
        'Callback',{@get_textbox_timePerFrame}, ...
        'Enable','off');

    % view options panel
    viewOptionsPanel = uipanel('Parent',guiCtrl, ...
        'Title','View Options', ...
        'Units','normalized', ...
        'FontSize',12, ...
        'Position',[0.01 0.002 0.4 0.119]);
    colorMapSelection = uicontrol('Parent',viewOptionsPanel, ...
        'Style','popupmenu', ...
        'String',{'Default Colormap' 'MATLAB Color: JET' 'MATLAB Color: Gray' 'MATLAB Color: hsv' 'MATLAB Color: Hot' 'MATLAB Color: Cool'}, ...
        'Units','normalized', ...
        'Position',[0.25 0.5 0.5 0.5], ...
        'Callback',{@change_color_map}, ...
        'Enable','off');
    roiSelection = uicontrol('Parent',viewOptionsPanel, ...
        'Style','popupmenu', ...
        'String',{'ROI: Circle' 'ROI: Ellipse' 'ROI: Freehand' 'ROI: AssistedFreehand' 'ROI: Polygon' 'ROI: Rectangle'}, ...
        'Units','normalized', ...
        'Position',[0.25 0 0.5 0.5], ...
        'Value',3, ...
        'Callback',{@change_roi_shape}, ...
        'Enable','off');
    % stack previewer 
    imagePanel = uipanel('Parent',guiCtrl, ...
        'Units','normalized', ...
        'Position',[0.415 0.130 0.575 0.870]);    
    imgAx = axes('Parent',imagePanel, ...
        'YTick',[],'XTick',[], ...
        'Units','normalized',...
        'Position',[0.025 0.05 0.95 0.85]);
    labelTitle = uicontrol('Parent',guiCtrl, ...
        'Style','text', ...
        'String','Image Frame: ', ...
        'Enable','on', ...
        'HorizontalAlignment','center',...
        'FontSize',12, ...
        'Units','normalized', ...
        'Position',[0.625 0.925 0.20 0.05]);
    channelSelection = uicontrol('Parent',guiCtrl, ...
        'Style','popupmenu', ...
        'String',{''}, ...
        'Units','normalized', ...
        'Position',[0.830 0.925 0.10 0.05], ...
        'Value',1, ...
        'callback',{@channel_changed}, ...
        'Enable','off');
    sliderTimepoint = uicontrol('Parent',imagePanel, ...
        'Style','slide', ...
        'Units','normalized', ...
        'position',[0 0 1 0.025], ...
        'min',1,'max',50,...
        'val',1, ...
        'SliderStep', [1 1]/(50-1), ...
        'Enable','off');
    addlistener(sliderTimepoint,'ContinuousValueChange',@(hObject, event) update_image_timepoint(hObject, event));

    % image queue
    imageQueuePanel = uipanel('Parent',guiCtrl, ...
        'Title', 'Image Queue Panel', ...
        'FontSize', 12, ...
        'Units','normalized', ...
        'Position',[0.165 0.1275 0.245 0.40]);
    imageQueueTable = uicontrol('Parent',imageQueuePanel, ...
        'Style','listbox', ...
        'Units','normalized', ...
        'Position',[0.01 0.05 0.98 0.90], ...
        'Callback',{@image_queue_selection}, ...
        'Enable','off');
    
%     uitable('Parent',imageQueuePanel, ...
%         'ColumnName',{pad('File Name', 63, 'both')}, ...
%         'RowName', {'1'},...
%         'Units','normalized', ...
%         'Position',[0.1 0.1 0.792 0.8], ...
%         'Enable','on', ...
%         'CellSelectionCallback',{@image_queue_selection});

    % Sphinctalyze button
    sphinctalyzeButton = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Sphinctalyze', ...
        'Enable','on', ...
        'FontSize',12,...
        'Units','normalized', ...
        'Position',[0.6275 0.05 0.15 0.075], ...
        'callback',{@sphinctalyze}, ...
        'Enable','off');
    % cancel button
    cancelButton = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Cancel', ...
        'Tooltip','Abort the analysis',...
        'Enable','on', ...
        'FontSize',12,...
        'Units','normalized', ...
        'Position',[0.830 0.05 0.15 0.075], ...
        'callback',{@cancel}, ...
        'Enable','off');
    % Reset button
    resetButton = uicontrol('Parent',guiCtrl, ...
        'Style','pushbutton', ...
        'String','Reset', ...
        'Tooltip','Relaunch the APP',...
        'Enable','on', ...
        'FontSize',12,...
        'Units','normalized', ...
        'Position',[0.425 0.05 0.15 0.075], ...
        'callback',{@resetCallback});
    % Disable the following uicontrols during the processing and
    % enable them after a successful analysis or when exceptions occur.
    handlesArray = [changeChannelNames,changeChannelNames,changeVelocityRange,...
        sru1,sru2,sru3,sru4,sru5,enterSpeed,enterStep,enterSmooth,enterDetection,...
        enterShape,enterMicronsPerPixel,enterNormalization,entertimePerFrame,...
        colorMapSelection,roiSelection,channelSelection,sliderTimepoint,imageQueueTable,sphinctalyzeButton,...
        openFile,postProcess,keepAnalysisOpen,cellInputs];  
    
  %GUI layout ends here ------------------------------------------------

    function open_file_callback(hObject, eventData)
        [imageName_get, imagePath_get] = uigetfile({'*.tif;*.tiff;'},'Select one or more images',imagePath,'MultiSelect','on');
        if isequal(imageName_get,0)
            disp('User canceled the image selection. No new image is loaded.')
            return
        elseif ~iscell(imageName_get)
            % User selected only one file
            imageName = imageName_get;
            imagePath = imagePath_get;
            currDate = strrep(datestr(datetime), ' ', '_');
            currDate = strrep(currDate,':','-');
            outputDirectory = fullfile(imagePath,'Sphincdata',sprintf('Output_%s',currDate));
            currentObj = 1;
            outputPath = fullfile(imagePath,'Sphincdata');
            load_image({imageName},imagePath,outputDirectory)
        else
            % User selected multiple files
            imageName = imageName_get;
            imagePath = imagePath_get;
            currDate = strrep(datestr(datetime), ' ', '_');
            currDate = strrep(currDate,':','-');
            outputDirectory = fullfile(imagePath,'Sphincdata',sprintf('Output_%s',currDate));
            currentObj = 1;
            outputPath = fullfile(imagePath,'Sphincdata');
            load_image(imageName,imagePath,outputDirectory)
        end
        set(loadParam,'Enable','off')
        fprintf(' "Load Parameters" button is disabled". \n To specify a parameters file for the anlaysis, click on the "Load Parameters" butoon before loading images. \n' )
    end
    

    function post_process_callback(hObject, eventData)
        processedPaths = {};
        outputDir = uigetdir(outputPath,'Pick the output folder containing valid results folder(s) of one or more movies');
        if outputDir == 0
            disp('NO output folder is selected')
            return
        else
            listAll = dir(fullfile(outputDir,'data*'));
            if ~isempty(listAll)
                listFolders = listAll([listAll(:).isdir]);
                % listFolders =
                % listFolders(~ismember({listFolders(:).name},{'.','..'}));
                % remove '.' and '..'
            else
                error('No valid outputDir folder is found')
            end

        end

        for i = 1:length(listFolders)
            selpath = fullfile(outputDir,listFolders(i).name);
            if isfile(fullfile(selpath,'parameters.mat'))
                processedPaths{end + 1} = selpath;
            else
                fprintf('NO parameters.mat file is found in %s \n', selpath)
            end
        end
        if ~isempty(processedPaths)
            if keepAnalysisOpen.Value == 0
                delete(guiCtrl);
            end
            % update previously processed images
            answerPost = questdlg('Overwrite Results_1 using pararmeters saved in parameters_post.xlsx or Results_1.xlsx file or default parameters file?', ...
                'Verify post-processing movie creatation', ...
                'YES','NO','YES');
            % Handle response
            switch answerPost
                case 'YES'
                    disp('Loading post-processing parameters saved in Results_1.xlsx file or default parameters for creating new movies...')
                    % PathtoParameters = fullfile(parameterFilePath,parameterFileName);

                    for j = 1:length(processedPaths)
                        %create new results for each movie using loaded parameters
                        fprintf('Movie creation: %d/%d \n',j,length(processedPaths));
                        if exist(fullfile(processedPaths{j},'sphincRedo','results_1.xlsx'),'file') ~=2 % if first file does not exit
                            disp('create the first results file using the previous saved parameters')
                            createNewMovie_post(processedPaths{j}); % create the first file using the previously saved parameters
                        end
                        createNewMovie_post(processedPaths{j});
                    end

                case 'NO'
                    disp('No new movie created the post-processing. Launch the post-processing GUI.')
            end

            postProcessingGUI(processedPaths)
            

        else
            disp('NO valid output folder is selected')
            return;
            end
       

    end

    function load_param_callback(hObject, eventData)
        [parameterCSVFileName_get, parameterFilePath_get] = uigetfile({'*.csv;'},'Select a parameter .csv file',parameterFilePath,'MultiSelect','off');

        if isequal(parameterCSVFileName_get,0)
            disp('User canceled the image selection. No image is loaded.')
            return
        else
            parameterCSVFileName = parameterCSVFileName_get;
            parameterFilePath = parameterFilePath_get;
            parameterFileName = strrep(parameterCSVFileName,'.csv','.mat');
            csvfileName = parameterCSVFileName;
            parameters = load(fullfile(parameterFilePath,parameterFileName));
            names = fieldnames(parameters);
            name = names(1);
            if ~isequal(class(parameters.(name{1})),'Image')
                errordlg('Please load a valid parameters file.');
            else
                matfileName = parameterFileName;
                parametersOld = parameters;%load(matfileName);
                parametersLoad = readcell(fullfile(parameterFilePath,csvfileName));
                parameters = parametersOld.parameters;
%                 parametersUpdate = parameters;
                propertiesList = properties(parameters);
                propertiesLength = length(propertiesList);
                [m,n] = size(parameters.cellArray); %m*n is the maximum number of values that one properties can contain
                propertyValue =  cell(propertiesLength,1+m*n);
                for iP = 1:propertiesLength
                    propertiesName = propertiesList{iP};
                    propertyValue{iP,1} = propertiesName;
                    if isempty(find(strcmp(propertiesName,{'cellArray','axesNames','channelNames','moviePaths'}),1))
                        if strcmp(propertiesName, 'channelColors') == 1
                            parameters.(propertiesName){1} = str2num(parametersLoad{iP,2});
                            parameters.(propertiesName){2} = str2num(parametersLoad{iP,3});
                            parameters.(propertiesName){3} = str2num(parametersLoad{iP,4});
                        elseif strcmp(propertiesName, 'xMinStepMax') == 1
                            parameters.(propertiesName) = str2num(parametersLoad{iP,2});
                        elseif strcmp(propertiesName, 'yMinStepMax') == 1
                            parameters.(propertiesName) = str2num(parametersLoad{iP,2});
                        elseif strcmp(propertiesName, 'velocityStartStop') == 1
                            parameters.(propertiesName) = [parametersLoad{iP,2} parametersLoad{iP,3}];
                        else
                            parameters.(propertiesName) = parametersLoad{iP,2};
                        end
                    else % for cell arrays: 'cellArray','axesNames','channelNames','moviePaths'
                        [m,n] = size(parameters.(propertiesName));
                        parametersCell = cell(m,n);
                        for iM = 1:m
                            for iN = 1:n
                                parameters.(propertiesName){iM,iN} = parametersLoad{iP,1+(iM-1)*n+iN};
                            end
                        end

                    end
                end
                % save .mat parameters
%                 [ParentFolderPath] = fileparts(ParentFolderPath);
                save(fullfile(parameterFilePath,parameterFileName),'parameters','-mat');
                fprintf('Parameter file %s is loaded from %s \n',parameterCSVFileName, parameterFilePath)
                fprintf('This file will be applied to subsequently loaded images. \n')
                loadParameters = 1;
                set(loadParam,'Enable','off')
                fprintf('"Load Parameters" button is disabled. \n To load a new parameters file, click on the "Reset" button to start over. \n' )
                msgbox("Parameters successfully loaded.");
            end
        end
    end
    
    function load_image(imageNames, imagePath, batchDirectory)
        % create an object array of length fileNames, with default values
        if loadParameters == 0
            imgarray(1:length(imageNames)) = Image(0,1,0,3,1,1,3,0,8,0,0, ...
                'gray',6,{'Distance (microns) from wound center','Normalized Gray Value'}, ...
                [-150 50 0] * 0.192,[-0.1 0.3 1.1],1,0.192,imagePath,0,0, ...
                {[1 0 0],[0 1 1],[0 0 1]},0,'NorthWest',3,batchDirectory, {}, [1 2]);
        else
            parameters = load(fullfile(parameterFilePath,parameterFileName));
            names = fieldnames(parameters);
            name = names(1);
            imgarray(1:length(imageNames)) = Image(parameters.(name{1}).cellArray, ...
                parameters.(name{1}).timepointStart, ...
                parameters.(name{1}).timepointEnd, ...
                parameters.(name{1}).speed, ...
                parameters.(name{1}).loadMulti, ...
                parameters.(name{1}).shape, ...
                parameters.(name{1}).detection, ...
                parameters.(name{1}).smooth, ...
                parameters.(name{1}).step, ...
                parameters.(name{1}).filePath, ...
                parameters.(name{1}).nTimepoints, ...
                parameters.(name{1}).colormap, ...
                parameters.(name{1}).timePerFrame, ...
                parameters.(name{1}).axesNames, ...
                parameters.(name{1}).xMinStepMax, ...
                parameters.(name{1}).yMinStepMax, ...
                parameters.(name{1}).normalization, ...
                parameters.(name{1}).micronsPerPixel, ...
                imagePath, ...
                parameters.(name{1}).imageName, ...
                parameters.(name{1}).channelNames, ...
                parameters.(name{1}).channelColors, ...
                parameters.(name{1}).darkBackground, ...
                parameters.(name{1}).legendLocation, ...
                parameters.(name{1}).roiShape, ...
                batchDirectory, ...
                {},...  %parameters.(name{1}).moviePaths, ...
                parameters.(name{1}).velocityStartStop);
        end
        objarray = imgarray;
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
            objarray(i).nTimepoints = nTimepoints;
            if loadParameters == 0 || (objarray(i).timepointStart == -1 && objarray(i).timepointEnd == -1)
                objarray(i).timepointEnd = nTimepoints;
                objarray(i).timepointStart = 1;
            end
            if nChannels == 1
                objarray(i).loadMulti = 0;
            end
            [nrow, ~] = size(objarray(i).cellArray);
            if loadParameters == 0
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
            elseif nrow ~= nChannels 
                cellArray = cell(nChannels, 3);
                for j = 1:nChannels
                    for k = 1:3
                        cellArray{j,k} = objarray(i).cellArray{j,k};
                    end
                end
                objarray(i).cellArray = cellArray;
                objarray(i).channelNames = {cellArray{:, 1}};
            end
        end

        % enable GUI parameters
        set(changeChannelNames,'Enable','on')
        set(changeVelocityRange,'Enable','on')
        set(sru1,'Enable','on')
        set(sru2,'Enable','on')
        set(enterSpeed,'Enable','on')
        set(enterStep,'Enable','on')
        set(enterSmooth,'Enable','on')
        set(enterDetection,'Enable','on')
        set(enterShape,'Enable','on')
        set(enterMicronsPerPixel,'Enable','on')
        set(enterNormalization,'Enable','on')
        set(entertimePerFrame,'Enable','on')
        set(colorMapSelection,'Enable','on')
        set(roiSelection,'Enable','on')
        set(channelSelection,'Enable','on')
        set(sliderTimepoint,'Enable','on')
        set(imageQueueTable,'Enable','on')
        set(sphinctalyzeButton,'Enable','on')
        set(cancelButton,'Enable','on')
        % set(resetButton,'Enable','on')
        set(keepAnalysisOpen, 'Enable','on')
        set(cellInputs,'Enable','on')
        update_parameters(currentObj)
        % Populate Image Queue
        imageNames = cell(length(objarray));
        for l = 1:length(objarray)
            imageNames{l} = objarray(l).imageName;
        end
        set(imageQueueTable,'String',imageNames)
        set(imageQueueTable, 'Value', 1)
    end
    
    function update_parameters(objIndex)
        obj = objarray(objIndex);
        cellInputs.Data = {};
        % fill cell inputs table
        for i = 1:obj.nChannels
            cellInputs.RowName{i, 1} = obj.cellArray{i, 1};
            for j = 1:2
                if j  == 1
                    cellInputs.Data{i, j} = obj.cellArray{i, j + 1};
                else
                    if obj.cellArray{i, j + 1} == 1
                        cellInputs.Data{i, j} = 'True';
                    elseif obj.cellArray{i, j + 1} == 0
                        cellInputs.Data{i, j} = 'False';
                    end
                end
            end
        end
        referenceColumn = [obj.cellArray{:,3}];
        if max(referenceColumn) == 0
            referenceChannel = 1;
            referenceFrame = cellInputs.Data{1,1};
        else
            referenceChannel = find(referenceColumn, 1);
            referenceFrame = cellInputs.Data{referenceChannel, 1};
        end

        set(cellInputs, 'ColumnEditable',true(1,2))

        % fill slice ranges panel
        if (obj.timepointEnd == obj.nTimepoints) && (obj.timepointStart == 1)
            set(sru1,'Value',1)
            set(sru2,'Value',0)
            set([sru3 sru4 sru5],'Enable','off')
            set([sru3 sru5], 'String', '')
        else
            set(sru1,'Value',0)
            set(sru2,'Value',1)
            set([sru3 sru4 sru5],'Enable','on')
            set(sru3,'String',num2str(obj.timepointStart))
            set(sru5,'String',num2str(obj.timepointEnd))
        end

        % Set Sphinctalyzer and Viewing parameters
        set(enterSpeed,'String', num2str(obj.speed))
        set(enterSpeed,'UserData', obj.speed)
        set(enterShape,'String', num2str(obj.shape))
        set(enterShape,'UserData', obj.shape)
        set(enterDetection,'String', num2str(obj.detection))
        set(enterDetection,'UserData', obj.detection)
        set(enterSmooth,'String', num2str(obj.smooth))
        set(enterSmooth,'UserData', obj.smooth)
        set(enterStep,'String', num2str(obj.step))
        set(enterStep,'UserData', obj.step)
        set(enterNormalization,'String', num2str(obj.normalization))
        set(enterNormalization,'UserData', obj.normalization)
        set(enterMicronsPerPixel,'String', num2str(obj.micronsPerPixel))
        set(enterMicronsPerPixel,'UserData', obj.micronsPerPixel)
        set(entertimePerFrame,'String', num2str(obj.timePerFrame))
        set(entertimePerFrame,'UserData', obj.timePerFrame)
        switch obj.colormap
            case 'gray'
                colorMapValue = 1;
            case 'jet'
                colorMapValue = 2;
            case 'hsv'
                colorMapValue = 4;
            case 'hot'
                colorMapValue = 5;
            case 'cool'
                colorMapValue = 6;
        end
        set(colorMapSelection,'Value', colorMapValue)
        set(roiSelection,'Value',obj.roiShape)
        
        % Load image into the previewer
        channels = cell(obj.nChannels, 1);
        for i = 1:length(channels)
            channels{i, 1} = "channel" + i;
        end
        set(channelSelection,'String',channels)
        set(channelSelection,'Value', referenceChannel)
        bfRederinfo = bfGetReader(fullfile(obj.imagePath, obj.imageName));
        iPlane =  bfRederinfo.getIndex(0, referenceChannel - 1, referenceFrame - 1) + 1;
        I = bfGetPlane( bfRederinfo, iPlane); 
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap);
        axis image equal
        drawnow
        set(sliderTimepoint,'Value',referenceFrame)
        set(sliderTimepoint,'max',obj.nTimepoints)
        set(sliderTimepoint,'SliderStep',[1 1] / (obj.nTimepoints - 1))
        set(labelTitle,'String',sprintf('Image Frame: %d/%d', referenceFrame, objarray(currentObj).nTimepoints))
    end

    function image_queue_selection(hObject, event)
        % If another image selected, update_parameter(objIndex)
        if hObject.Value > length(objarray)
            set(hObject,'Value',length(objarray))
            return
        end
        currentObj = hObject.Value;
        update_parameters(hObject.Value)
    end

    function sphinctalyze(hObject, eventdata)
        % Run sphinctalyerinitalizer on all images
        % disable the GUI parameters during the process
        set(handlesArray,'Enable','off')
        % obj.batchDirectory = '/Users/ympro/Desktop/BementLabSphinctalyzer/test_datasets/Sphincdata/Output_07-Dec-2023_08-50-00';
        skippedobjIndex1 = [];
        for i = 1:length(objarray)
            try
                obj = objarray(i);
                file = SphinctalyzerInitializer(obj.cellArray,obj.timepointStart, ...
                    obj.timepointEnd, ...
                    obj.speed, ...
                    obj.loadMulti,...
                    obj.shape, ...
                    obj.detection, ...
                    obj.smooth, ...
                    obj.step,...
                    obj.imagePath, ...
                    obj.imageName,obj.colormap, ...
                    obj.roiShape, ...
                    obj.batchDirectory);
                obj.filePath = file;
                objarray(i) = obj;
            catch ME
                set(handlesArray,'Enable','on')
                fprintf(' Initialize of object %d  did not go through, error message: %s \n',i,ME.message)
                fprintf ('Image %d %s is skipped \n',i,objarray(i).imageName)
                skippedobjIndex1 = [skippedobjIndex1 i];
            end

        end
       if ~isempty(skippedobjIndex1)
           skip_handling(skippedobjIndex1);    
       else
           disp('Path annotation for all images has gone through, proceed to the next operation' )
       end
        skippedobjIndex2 = [];
        for i = 1:length(objarray)
            fprintf('Ongoing processing %d/%d: %s \n',i,length(objarray),objarray(i).imageName)
            try
                obj = objarray(i);
                % Run sphincrescue and movieplotter on all images
                [ParentFolderPath] = fileparts(obj.filePath);
                [ParentFolderPath] = fileparts(ParentFolderPath);

                SphincRescue(ParentFolderPath, ...
                    obj.speed, ...
                    obj.loadMulti, ...
                    obj.shape, ...
                    obj.detection, ...
                    obj.step)

                SphinctalyzerMoviePlotterMulti(ParentFolderPath, ...
                    obj.channelColors, ...
                    obj.axesNames, ...
                    obj.darkBackground, ...
                    obj.timePerFrame, ...
                    obj.normalization, ...
                    obj.legendLocation, ...
                    obj.micronsPerPixel, ...
                    obj.xMinStepMax, ...
                    obj.yMinStepMax, ...
                    1, ...
                    obj.imageName,...
                    obj.velocityStartStop)

                % set movie path for the movie
                ParentFolderPath = fullfile(ParentFolderPath,'sphincRedo');
                validnames=dir(fullfile(ParentFolderPath, '*.avi'));
                for j=1:size(validnames,1)
                    obj.moviePaths = [obj.moviePaths; fullfile(validnames(j).folder,validnames(j).name)];
                end
                parameters = obj;
                % save parameters
                [ParentFolderPath] = fileparts(ParentFolderPath);
                save(fullfile(ParentFolderPath,'parameters.mat'),'parameters','-mat');
                %save editable parameters into a csv file
                csvfileName = 'parameters.csv';
                propertiesList = properties(parameters);
                propertiesLength = length(propertiesList);
                [m,n] = size(parameters.cellArray); %m*n is the maximum number of values that one properties can contain
                csvfileValue =  cell(propertiesLength,1+m*n);
                for iP = 1:propertiesLength
                    propertiesName = propertiesList{iP};
                    csvfileValue{iP,1} = propertiesName;
                    if isempty(find(strcmp(propertiesName,{'cellArray','axesNames','channelNames','moviePaths'}),1))
                        if strcmp(propertiesName, 'channelColors') == 1
                            csvfileValue{iP,2} = mat2str(parameters.(propertiesName){1});
                            csvfileValue{iP,3} = mat2str(parameters.(propertiesName){2});
                            csvfileValue{iP,4} = mat2str(parameters.(propertiesName){3});
                        elseif strcmp(propertiesName, 'xMinStepMax') == 1
                            csvfileValue{iP,2} = mat2str(parameters.(propertiesName));
                        elseif strcmp(propertiesName, 'yMinStepMax') == 1
                            csvfileValue{iP,2} = mat2str(parameters.(propertiesName));
                        elseif strcmp(propertiesName, 'velocityStartStop') == 1
                            csvfileValue{iP,2} = parameters.(propertiesName)(1);
                            csvfileValue{iP,3} = parameters.(propertiesName)(2);
                        else
                            csvfileValue{iP,2} = parameters.(propertiesName);
                        end
                    else % for cell arrays: 'cellArray','axesNames','channelNames','moviePaths'
                        [m,n] = size(parameters.(propertiesName));
                        for iM = 1:m
                            for iN = 1:n
                                csvfileValue{iP,1+(iM-1)*n+iN} =  parameters.(propertiesName){iM,iN};
                            end
                        end
                    end
                end
                %             writecell(csvfileValue, fullfile(ParentFolderPath,csvfileName));
                writecell(csvfileValue, fullfile(ParentFolderPath,csvfileName));
                objarray(i) = obj;
            catch exp1
                fprintf(' Analysis of Object %d  did not go through, error message: %s \n',i,exp1.message)
                fprintf ('Image %d %s is skipped \n',i,objarray(i).imageName)
                skippedobjIndex2 = [skippedobjIndex2 i];
            end
        end
        if ~isempty(skippedobjIndex2)
            skip_handling(skippedobjIndex2)
        else
            disp('All images on the list have been succesfully sphinctalyzed.')
            
        end

    % run output data gui
        if ~isempty(objarray) 
            sphinctalyzerOutput(objarray)
        else
            disp('NO valid image is available. Load image(s) to proceed')
            set(handlesArray,'Enable','on')
            return
        end
        
        if ~get(keepAnalysisOpen, 'Value')
            delete(guiCtrl);
        else
            % make new directory for each new analysis in SphinctalyzerImageLoader
            currDate = strrep(datestr(datetime), ' ', '_');
            currDate = strrep(currDate,':','-');
            % pathString = strcat(imagePath,'/Sphincdata/Output_',currDate)
            pathString = fullfile(imagePath,'Sphincdata',sprintf('Output_%s',currDate));
            for i = 1:length(objarray)
                objarray(i).batchDirectory = pathString;
                objarray(i).moviePaths = {};
            end
            % update_parameters(objarray)
            set(handlesArray,'Enable','on')
        end
    end
    
% Cancel or abort a process
    function cancel(hObject,event)
         set(handlesArray,'Enable','on')
         % sphinctalyzerInitializerGUI
        delete(findall(0,'Type','Figure','-not','Tag','mainGUI'))
        disp('Cancel or abort the process')
    end
% Relaunch the app
    function resetCallback(hObject,event)
        disp('Restart the process')
        sphinctalyzerInitializerGUI
    end
    
    function update_image_timepoint(hObject,event)
        obj = objarray(currentObj);
        file = fullfile(obj.imagePath, obj.imageName);
        currentChannel = get(channelSelection, 'Value') - 1;
        % get timepoint of slider
        iTimepoint = round(sliderTimepoint.Value); 
        
        % update title text
        set(labelTitle,'String',sprintf('Image Frame: %d/%d', iTimepoint, obj.nTimepoints))

        % display it on the image axes
        bfRederinfo = bfGetReader(file);
        bfRederinfo.setSeries(0);
        iPlane =  bfRederinfo.getIndex(0, currentChannel, iTimepoint-1) + 1;
        I = bfGetPlane(bfRederinfo, iPlane);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap);   
        axis image equal
        drawnow 
    end

    % Callback functions
    function cell_inputs_callback(hObject, event)
        % update obj cell array using the cell inputs  table
        if isnan(event.NewData)
            hObject.Data{event.DisplayIndices(1),event.DisplayIndices(2)} = event.PreviousData;
            return
        end
        row = event.Indices(1);
        column = event.Indices(2);
        if column == 1
            if row > objarray(currentObj).nChannels
                cellInputs.Data{row,column} = event.PreviousData;
                errordlg('Please only change the display frame value for labelled channels.')
                return
            end
            if event.NewData < 1 || event.NewData > objarray(currentObj).nTimepoints
                hObject.Data{event.DisplayIndices(1),event.DisplayIndices(2)} = event.PreviousData;
                errordlg('Please enter a display frame value in the range of timepoints.')
            end
            objarray(currentObj).cellArray{row, column + 1} = event.NewData;
        elseif column == 2
            if row > objarray(currentObj).nChannels
                cellInputs.Data{row,column} = event.PreviousData;
                errordlg('Please only change the isReference checkbox for labelled channels.')
                return
            end
            if event.PreviousData == "False"
                cellInputs.Data{row,column} = 'True';
                objarray(currentObj).cellArray{row, column + 1} = 1;
            elseif event.PreviousData == "True"
                cellInputs.Data{row,column} = 'False';
                objarray(currentObj).cellArray{row, column + 1} = 0;
            end
        end
%         objarray(currentObj).cellArray{row, column + 1} = event.NewData;
        % update stack previewer
        if column == 1
            if hObject.Data{row , 2}
                file = fullfile(objarray(currentObj).imagePath, objarray(currentObj).imageName);
                set(channelSelection, 'Value', row)
                % set timepoint of slider
                iTimepoint = event.NewData;
                set(sliderTimepoint,'Value',iTimepoint)
                
                % update title text
                set(labelTitle,'String',sprintf('Image Frame: %d/%d', iTimepoint, objarray(currentObj).nTimepoints))
        
                % display it on the image axes
                bfRederinfo = bfGetReader(file);
                bfRederinfo.setSeries(0);
                iPlane =  bfRederinfo.getIndex(0, row - 1, iTimepoint-1) + 1;
                I = bfGetPlane(bfRederinfo, iPlane);
                imagesc(I,'Parent',imgAx);
                set(imgAx,'YTick',[],'XTick',[]);
                colormap(imgAx,objarray(currentObj).colormap);   
                axis image equal
                drawnow 
            end
        end
    end
    
    function prompt_names(hObject, event)
        % prompt the user for new channel names
        obj = objarray(currentObj);
        nChannels = obj.nChannels;
        prompts = cell(obj.nChannels, 1);
        for i = 1:length(prompts)
            prompts{i} = "Enter name of channel " + i + ":";
        end
        dims = [1 35];
        definput = cell(nChannels, 1);
        if nChannels == 1
            definput = {cellInputs.RowName{1, 1}};
        elseif nChannels == 2
            definput = {cellInputs.RowName{1, 1}, cellInputs.RowName{2, 1}};
        elseif nChannels == 3
            definput = {cellInputs.RowName{1, 1}, cellInputs.RowName{2, 1}, cellInputs.RowName{3, 1}};
        end
        dlgtitle = 'Edit Channel Names';
        answer = inputdlg(prompts,dlgtitle,dims,definput);
        if ~isempty(answer)
            % update the channel name
            for iC = 1:nChannels
                if ~isempty(answer{iC})
                    obj.cellArray{iC, 1} = answer{iC};
                    obj.channelNames{iC} = answer{iC};
                    cellInputs.RowName{iC, 1} = answer{iC};
                else
                    fprintf('Name of Channel %d is not entered.Channel %d name NOT changed \n', iC, iC)
                end
            end
        else
            disp('Channel name NOT changed ')
        end
        objarray(currentObj) = obj;
    end
    
    function slice_selection_changed(hObject, event)
        obj = objarray(currentObj);
        if strcmp(get(get(hObject,'SelectedObject'),'String'),'Slices')
            set([sru3 sru4 sru5],'Enable','on')
        else
            set([sru3 sru4 sru5],'Enable','off')
            set([sru3 sru5],'String','')
            obj.timepointStart = 1;
            obj.timepointEnd = obj.nTimepoints;
        end
        objarray(currentObj) = obj;
    end

    function get_textbox_sru3(sru3, event)
        usr_input = get(sru3,'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number within the slice range.')
            set(sru3,'String',num2str(get(sru3,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 1 || usr_input > (objarray(currentObj).nTimepoints - 1)
            errordlg('Please enter a number within the slice range.')
            set(sru3,'String',num2str(get(sru3,'UserData')))
            return
        end
        set(sru3,'UserData',usr_input)
        objarray(currentObj).timepointStart = usr_input;
        if usr_input > objarray(currentObj).velocityStartStop(1)
            objarray(currentObj).velocityStartStop(1) = usr_input;
            objarray(currentObj).velocityStartStop(2) = objarray(currentObj).timepointEnd;
        end
    end
    
    function get_textbox_sru5(sru5, event)
        usr_input = get(sru5,'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number within the slice range.')
            set(sru5,'String',num2str(get(sru5,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 1 || usr_input > (objarray(currentObj).nTimepoints)
            errordlg('Please enter a number within the slice range.')
            set(sru5,'String',num2str(get(sru5,'UserData')))
            return
        end
        set(sru5,'UserData',usr_input)
        objarray(currentObj).timepointEnd = usr_input;
        if usr_input < objarray(currentObj).velocityStartStop(2)
            objarray(currentObj).velocityStartStop(2) = usr_input;
            objarray(currentObj).velocityStartStop(1) = objarray(currentObj).timepointStart;
        end
    end
    
    function get_textbox_speed(enterSpeed, eventdata)
        usr_input = get(enterSpeed, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterSpeed,'String',num2str(get(enterSpeed,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 0
            errordlg('Please enter a positive number.')
            set(enterSpeed,'String',num2str(get(enterSpeed,'UserData')))
            return
        end
        set(enterSpeed, 'UserData', usr_input)
        objarray(currentObj).speed = usr_input;
    end
    
    function get_textbox_shape(enterShape, eventdata)
        usr_input = get(enterShape, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterShape,'String',num2str(get(enterShape,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 0
            errordlg('Please enter a positive number.')
            set(enterShape,'String',num2str(get(enterShape,'UserData')))
            return
        end
        set(enterShape, 'UserData', usr_input)
        objarray(currentObj).shape = usr_input;
    end
    
    function get_textbox_detection(enterDetection, eventdata)
        usr_input = get(enterDetection, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterDetection,'String',num2str(get(enterDetection,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input ~= 0 && usr_input ~= 3
            errordlg('Please enter either 0 or 3.')
            set(enterDetection,'String',num2str(get(enterDetection,'UserData')))
            return
        end
        set(enterDetection, 'UserData', usr_input)
        objarray(currentObj).detection = usr_input;
    end
    
    function get_textbox_smooth(enterSmooth, eventdata)
        usr_input = get(enterSmooth, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterSmooth,'String',num2str(get(enterSmooth,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input ~= 0
            errordlg('Please enter 0.')
            set(enterSmooth,'String',num2str(get(enterSmooth,'UserData')))
            return
        end
        set(enterSmooth, 'UserData', usr_input)
        objarray(currentObj).smooth = usr_input;
    end
    
    function get_textbox_step(enterStep, eventdata)
        usr_input = get(enterStep, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterStep,'String',num2str(get(enterStep,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 0
            errordlg('Please enter a positive number.')
            set(enterStep,'String',num2str(get(enterStep,'UserData')))
            return
        end
        set(enterStep, 'UserData', usr_input)
        objarray(currentObj).step = usr_input;
    end

    function get_textbox_normalization(enterNormalization, eventdata)
        obj = objarray(currentObj);
        usr_input = get(enterNormalization, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterNormalization,'String',num2str(get(enterNormalization,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if ~ismember(usr_input, [1 2 3 4]) 
            errordlg('Please enter 1-4.')
            set(enterNormalization,'String',num2str(get(enterNormalization,'UserData')))
            return
        end
        set(enterNormalization, 'UserData', usr_input)
        axesNames = obj.axesNames;
        obj.normalization = usr_input;
        switch usr_input
            case 1
                axesNames{2} = 'Normalized Gray Value';
                obj.yMinStepMax = [-0.1 0.1 1.1];
            case 2
                axesNames{2} = 'Fold Over Background';
                obj.yMinStepMax = [-1 1 6];
            case 3
                axesNames{2} = 'Gray Value';
                obj.yMinStepMax = [0 500 4100];
            otherwise
                axesNames{2} = 'Normalized Gray Value';
                obj.yMinStepMax = [-0.1 .1 1.1];
        end
        obj.axesNames = axesNames;
        objarray(currentObj) = obj;
    end

    function get_textbox_micronsPerPixel(enterMicronsPerPixel, eventdata)
        obj = objarray(currentObj);
        prev_input = get(enterMicronsPerPixel, 'UserData');
        xMinStepMax = obj.xMinStepMax;
        xMinStepMax = round(xMinStepMax / prev_input);
        usr_input = get(enterMicronsPerPixel, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterMicronsPerPixel,'String',num2str(get(enterMicronsPerPixel,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 0
            errordlg('Please enter a positive number.')
            set(enterMicronsPerPixel,'String',num2str(get(enterMicronsPerPixel,'UserData')))
            return
        end
        set(enterMicronsPerPixel, 'UserData', usr_input)
        axesNames = obj.axesNames;
        obj.micronsPerPixel = usr_input;
        switch usr_input
            case 1
                axesNames{1} = 'Distance (pixels) from wound center';
            otherwise
                axesNames{1} = 'Position (Microns) relative to wound center';
                xMinStepMax = usr_input * xMinStepMax;
                obj.xMinStepMax = xMinStepMax;
        end
        obj.axesNames = axesNames;
        objarray(currentObj) = obj;
    end

    function get_textbox_timePerFrame(entertimePerFrame, eventdata)
        usr_input = get(entertimePerFrame, 'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(entertimePerFrame,'String',num2str(get(entertimePerFrame,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 0
            errordlg('Please enter a positive number.')
            set(entertimePerFrame,'String',num2str(get(entertimePerFrame,'UserData')))
            return
        end
        set(enterStep, 'UserData', usr_input)
        objarray(currentObj).timePerFrame = usr_input;
    end

    function change_color_map(hObject, eventdata)
        obj = objarray(currentObj);
        selection = hObject.Value;
        colorMaps = hObject.String;
        switch colorMaps{selection}
            case 'Default Colormap'
                obj.colormap = 'gray';  
            case 'MATLAB Color: JET'
                obj.colormap = 'jet'; 
            case 'MATLAB Color: Gray'
                obj.colormap = 'gray'; 
            case 'MATLAB Color: hsv'
                obj.colormap = 'hsv'; 
            case 'MATLAB Color: Hot'
                obj.colormap = 'hot'; 
            case 'MATLAB Color: Cool'
                obj.colormap = 'cool'; 
        end
        objarray(currentObj) = obj;
        iTimepoint = round(sliderTimepoint.Value); 
        currentChannel = get(channelSelection, 'Value') - 1;
        file = fullfile(obj.imagePath, obj.imageName);
        bfRederinfo = bfGetReader(file);
        bfRederinfo.setSeries(0);
        iPlane =  bfRederinfo.getIndex(0, currentChannel, iTimepoint - 1) + 1;
        I = bfGetPlane(bfRederinfo, iPlane);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap);   
        axis image equal
        drawnow
        set(labelTitle,'String',sprintf('Image Frame: %d/%d', iTimepoint, obj.nTimepoints))
    end

    function change_roi_shape(hObject, eventdata)
        objarray(currentObj).roiShape = hObject.Value;
    end

    function channel_changed(hObject, eventdata)
        currentChannel = hObject.Value - 1;
        obj = objarray(currentObj);
        iTimepoint = round(sliderTimepoint.Value); 
        file = fullfile(obj.imagePath, obj.imageName);
        bfRederinfo = bfGetReader(file);
        bfRederinfo.setSeries(0);
        iPlane =  bfRederinfo.getIndex(0, currentChannel, iTimepoint - 1) + 1;
        I = bfGetPlane(bfRederinfo, iPlane);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap);   
        axis image equal
        drawnow
        set(labelTitle,'String',sprintf('Image Frame: %d/%d', iTimepoint, obj.nTimepoints))
    end

    function velocity_range(hObject, eventdata)
        obj = objarray(currentObj);
        prompts = {'Enter a starting frame:','Enter a final frame:'};
        dims = [1 35];
        velocityStartStop = obj.velocityStartStop;
        definput = {num2str(velocityStartStop(1)) num2str(velocityStartStop(2))};
        dlgtitle = 'Edit Velocity Range';
        answer = inputdlg(prompts,dlgtitle,dims, definput);
        if ~isempty(answer)
            if ~isempty(answer{1})
                if ~isnan(str2double(answer{1}))
                    velocityStartStop(1) = str2double(answer{1});
                else
                    errordlg('Please enter a number.')
                end
            end
            if ~isempty(answer{2})
                if ~isnan(str2double(answer{2}))
                    velocityStartStop(2) = str2double(answer{2});
                else
                    errordlg('Please enter a number.')
                end
            end
            if obj.timepointStart > velocityStartStop(1) || velocityStartStop(1) >= obj.timepointEnd
                errordlg('Please enter a range within the slice range.')
            elseif velocityStartStop(2) > obj.timepointEnd
                errordlg('Please enter a range within the slice range.')
            elseif (velocityStartStop(1) >= velocityStartStop(2))
                errordlg('Please enter a valid range.')
            else
                obj.velocityStartStop = velocityStartStop;
                objarray(currentObj) = obj;
            end
        end
    end
    
    function skip_handling(skippedobjIndex)
        objarray(skippedobjIndex) = [];
        if ~isempty(objarray)
            %update the image list
            imageNames = cell(length(objarray));
            for l = 1:length(objarray)
                imageNames{l} = objarray(l).imageName;
            end
            set(imageQueueTable,'String',imageNames)
            set(imageQueueTable, 'Value', 1)
            currentObj = 1;
        else
            set(imageQueueTable,'String','')
            set(handlesArray,'Enable','on')
            error('All is skipped. Load new image(s) to proceed')
        end
    end

end