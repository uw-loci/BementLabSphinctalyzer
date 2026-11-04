function sphinctalyzerOutput(objarray)
    % display GUI with:
    % - normalization and microns per pixel parameters
    % - movie plot options
    % - colormap options
    % - image queue
    % - preview image slider with the stuff
    % - button for each display interface (line scan movie, etc)

    % Set global params
    global mov xlsSheets oneIndices SphinctalyzerOutputs
    currentObj = 1;
    pauseS = false;
    iChannel = 1;
    iTimepoint = 1;
    frameRate = 20;
    readFunction = {@bf_reader, @circle_reader, @movie_reader};
    defaultPeakSearchingRadius = getDefaultPeakSearchingRadius();
    advancedOptions = struct('peakSearchingRadius',defaultPeakSearchingRadius,'velocityStartStop',[],'closingCheckpoint',[0.667 0.500 0.333],'closingCheckBasis','position');
    dataPlotFig = [];    % handle for the floating 'Data over time' figure
    currentExcelSavename = 'Results_1.xlsx';  % tracks which Results file is active
    xlsChannelNames = {};  % channel names read from the active Excel results file
    xlsFrameNums    = [];  % frame numbers read from column B of the active Excel results file
    % display GUI
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    guiCtrl = figure('Resize','on', ...
        'Color',defaultBackground', ...
        'Units','normalized', ...
        'Position',[0.25 0.25 0.65 0.65], ...
        'Visible','on',...
        'MenuBar','none', ...
        'name', 'Sphinctalyzer: Results', ...
        'NumberTitle','off', ...
        'CloseRequestFcn', @results_window_close_callback);
    
    % line scan movie options
    movieVelocityOptions = uipanel('Parent',guiCtrl, ...
        'Title','Movie Plot and Velocity Options', ...
        'Units','normalized', ...
        'FontSize', 12, ...
        'Position',[0.005 0.4 0.33 0.6]);

    moviePlotOptions = uipanel('Parent',movieVelocityOptions, ...
        'Title','Movie Plot', ...
        'Units','normalized', ...
        'FontSize', 12, ...
        'Position',[0.01 0.10 0.475 0.875]);
    changeXAxis = uicontrol('Parent',moviePlotOptions, ...
        'Style','pushbutton', ...
        'String','Edit X Axis', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0.15 0.9 .70 .075], ...
        'Callback',{@change_x_axis});   
    changeYAxis = uicontrol('Parent',moviePlotOptions, ...
        'Style','pushbutton', ...
        'String','Edit Y Axis', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0.15 0.8 .70 .075], ...
        'Callback',{@change_y_axis});
    % darkBackgroundLabel = uicontrol('Parent',moviePlotOptions, ...
    %     'Style','text', ...
    %     'String','Dark Background', ...
    %     'FontSize',10, ...
    %     'Units','normalized', ...
    %     'Position',[0 0.675 .65 .075]);
    darkBackground = uicontrol('Parent',moviePlotOptions, ...
        'Style','checkbox', ...
        'Enable','on', ...
        'String','Dark Background', ...
        'Min',0,'Max',1, ...
        'Units','normalized', ...
        'FontSize',10, ...
        'Position', [.25 .70 .75 .075], ...
        'Value', 0, ...
        'Callback', {@darkBackgroundCbx});  
    % parameters for controls
    h_start = 0.9;
    h_distance = 0.1;
    value_start = 0.725;
    value_width = 0.25;
    value_height = 0.075;
    text_start = 0;
    text_width = 0.7;
    fontsize_option1 = 10;

    normalizationLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Normalization', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units', 'normalized', ...
        'Position',[text_start h_start-0.3 text_width value_height]);
    enterNormalization = uicontrol('Parent',moviePlotOptions, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[value_start h_start-0.285 value_width value_height], ...
        'Callback',{@get_textbox_normalization});
    micronsPerPixelLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Microns Per Pixel', ...
        'FontSize',10, ...
        'HorizontalAlignment','right',...
        'Units', 'normalized', ...
        'Position',[text_start h_start-0.4 text_width value_height]);
    enterMicronsPerPixel = uicontrol('Parent',moviePlotOptions, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[value_start h_start-0.385 value_width value_height], ...
        'Callback',{@get_textbox_micronsPerPixel});
    timePerFrameLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Time Per Frame', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.5 text_width value_height]);
    enterTimePerFrame = uicontrol('Parent',moviePlotOptions, ...
        'Style','edit', ...
        'String',num2str(getappdata(guiCtrl,'timePerFrame')), ...
        'BackgroundColor', ...
        'w', ...
        'Min',0,'Max',1, ...
        'UserData',getappdata(guiCtrl,'timePerFrame'),'Units', ...
        'normalized', ...
        'Position',[value_start h_start-0.485 value_width value_height], ...
        'Callback',{@get_timePerFrame});
    legendLocationLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Legend Loc', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','center',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.6 text_width-0.25 value_height]);
    enterLegendLocation = uicontrol('Parent',moviePlotOptions, ...
        'Style','popupmenu', ...
        'String',{'NorthWest','NorthEast','SouthWest','SouthEast'}, ...
        'units','normalized', ...
        'Value',1 ,...
        'Position',[value_start-0.3 h_start-0.585 value_width+0.30 value_height], ...
        'Callback',{@get_legend_location});


    %Button to change the channel names
    changeChannelNames = uicontrol('Parent',moviePlotOptions,...
        'Style','pushbutton','String','Change Channel Name', ...
        'Units','normalized', ...
        'Position',[0.05 0.0025 .90 .075],...
        'Callback',{@changeChannelNames_callback});
    defaultChannelNames = {'Channel1','Channel2','Channel3'}; %

% peak dection options
     peakVelocityOptions = uipanel('Parent',movieVelocityOptions, ...
        'Title','Peak and Velocity', ...
        'Units','normalized', ...
        'FontSize', 12, ...
        'Position',[0.515 0.10 0.475 0.875]);  

     enterSearchingRadiusLabel = uicontrol('Parent',peakVelocityOptions, ...
        'Style','text', ...
        'String','Searching Radius', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units', 'normalized', ...
        'Position',[text_start h_start-0.10 text_width-0.075 value_height]);

     enterSearchingRadius = uicontrol('Parent',peakVelocityOptions, ...
         'Style','edit', ...
         'String',num2str(defaultPeakSearchingRadius), ...
         'Tooltip','in microns',...
         'Units','normalized',...
         'BackgroundColor','w', ...
         'UserData',defaultPeakSearchingRadius, ...
         'Position',[value_start-0.1 h_start-0.085 value_width+0.105 value_height], ...
         'Callback',{@get_searchingRadius});

         
         velocityRangeC1Label = uicontrol('Parent',peakVelocityOptions, ...
        'Style','text', ...
        'String','Velocity Range-C1', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.3 text_width-0.075 value_height]);

         enterVelocityRangeC1 = uicontrol('Parent',peakVelocityOptions, ...
        'Style','edit', ...
        'String','1 2', ...
        'Units','normalized',...
        'BackgroundColor','w', ...
        'UserData',[1 2],...
        'Position',[value_start-0.1 h_start-0.285 value_width+0.105 value_height], ...
        'Tooltip','velocity start and end for channel-1, seperated by space',...
        'Callback',{@get_velocityRangeC1});  

         velocityRangeC2Label = uicontrol('Parent',peakVelocityOptions, ...
        'Style','text', ...
        'String','Velocity Range-C2', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.4 text_width-0.075 value_height]);

         enterVelocityRangeC2 = uicontrol('Parent',peakVelocityOptions, ...
        'Style','edit', ...
        'String','1 2', ...
        'Units','normalized',...
        'BackgroundColor','w', ...
        'UserData',[1 2],...
        'Position',[value_start-0.1 h_start-0.385 value_width+0.105 value_height], ...
        'Tooltip','velocity start and end for channel-2, seperated by space',...
        'Enable','off',...
        'Callback',{@get_velocityRangeC2});  

        velocityRangeC3Label = uicontrol('Parent',peakVelocityOptions, ...
        'Style','text', ...
        'String','Velocity Range-C3', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.5 text_width-0.075 value_height]);

         enterVelocityRangeC3 = uicontrol('Parent',peakVelocityOptions, ...
        'Style','edit', ...
        'String','1 2', ...
        'Units','normalized',...
        'BackgroundColor','w', ...
        'UserData',[1 2],...
        'Position',[value_start-0.1 h_start-0.485 value_width+0.105 value_height], ...
        'Tooltip','velocity start and end for channel-3, seperated by space',...
        'Enable','off',...
        'Callback',{@get_velocityRangeC3});  

         closingCheckpointLabel = uicontrol('Parent',peakVelocityOptions, ...
        'Style','text', ...
        'String','Closing Check', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.7 text_width-0.175 value_height]);

         enterClosingCheckpoint = uicontrol('Parent',peakVelocityOptions, ...
        'Style','edit', ...
        'String','0.667 0.500 0.333', ...
        'Units','normalized',...
        'BackgroundColor','w', ...
        'UserData',[0.667 0.500 0.333],...
        'Position',[value_start-0.2 h_start-0.685 value_width+0.205 value_height], ...
        'Tooltip','wound opening fraction : 1: fully open at velocity start; 0: fully closed at wound center',...
        'Enable','on',...
        'Callback',{@get_closingCheckpoint});

         closingCheckBasisLabel = uicontrol('Parent',peakVelocityOptions, ...
        'Style','text', ...
        'String','Check Basis', ...
        'FontSize',fontsize_option1, ...
        'HorizontalAlignment','right',...
        'Units','normalized', ...
        'Position',[text_start h_start-0.8 text_width-0.175 value_height]);

         selectClosingCheckBasis = uicontrol('Parent',peakVelocityOptions, ...
        'Style','popupmenu', ...
        'String',{'Peak position','Ring area'}, ...
        'Units','normalized',...
        'Value',1,...
        'Position',[value_start-0.2 h_start-0.785 value_width+0.205 value_height], ...
        'Tooltip',sprintf(['Peak position: frame where the peak location is the given fraction of its value at velocity start\n' ...
            'Ring area: frame where the ring area is the given fraction of the area at velocity start']),...
        'Enable','on',...
        'Callback',{@get_closingCheckBasis});

         %create three buttons write one, save Post-parameters, and write
         %all
         gap2Edge = 0.025;
         buttonWidth = 0.30;
         buttonGap = (1-3*buttonWidth-2*gap2Edge)/2;
         %write single movie button 
         writeMovieButton = uicontrol('Parent',movieVelocityOptions, ...
             'Style','pushbutton', ...
             'String','Write One', ...
             'Units', 'Normalized', ...
             'Tooltip','Post-Process the current selected movie to write a movie with current parameters',...
             'Position',[gap2Edge 0.01 buttonWidth 0.075], ...
             'Callback',{@write_movie});
         %save current parameters button
         saveParametersButton = uicontrol('Parent',movieVelocityOptions, ...
             'Style','pushbutton', ...
             'String','Save Parameters', ...
             'Units', 'Normalized', ...
             'Tooltip','Save the current post-processing parameters to the parameters_post.xlsx file',...
             'Position',[gap2Edge+buttonWidth+buttonGap 0.01 buttonWidth 0.075], ...
             'Callback',{@save_postParameters});
         %write movie button
         writeMovieButton = uicontrol('Parent',movieVelocityOptions, ...
             'Style','pushbutton', ...
             'String','Write All', ...
             'Units', 'Normalized', ...
             'Tooltip','Post-Process all movies in the image list and save results into the Results_1 files',...
             'Position',[gap2Edge+2*buttonWidth+2*buttonGap 0.01 buttonWidth 0.075], ...
             'Callback',{@write_movies});
 
    %view options panel
    viewOptionsPanel = uipanel('Parent',guiCtrl, ...
        'Title','View Options', ...
        'Units','normalized', ...
        'FontSize', 12, ...
        'Position',[0.005 0.002 0.33 0.38]);
    colorMapSelection = uicontrol('Parent',viewOptionsPanel, ...
        'Style','popupmenu', ...
        'String',{'Default Colormap' 'MATLAB Color: JET' 'MATLAB Color: Gray' 'MATLAB Color: hsv' 'MATLAB Color: Hot' 'MATLAB Color: Cool'}, ...
        'Units','normalized', ...
        'Position',[0.15 0.83 0.7 0.12], ...
        'Callback',{@change_color_map});
    % data over time label | frame-axis checkbox | save button (all one row)
    % y = 0.72 = top of dropdown, so this row sits flush above it
    uicontrol('Parent',viewOptionsPanel, ...
        'Style','text', ...
        'String','Data over time', ...
        'FontSize',9, ...
        'HorizontalAlignment','left', ...
        'Units','normalized', ...
        'Position',[0.05 0.72 0.22 0.09]);
    showFrameAxisCheckbox = uicontrol('Parent',viewOptionsPanel, ...
        'Style','checkbox', ...
        'String','Show frame axis', ...
        'Value',1, ...
        'Enable','off', ...
        'Units','normalized', ...
        'Position',[0.27 0.72 0.38 0.09], ...
        'Callback',{@(~,~) refresh_data_plot()});
    % data over time measurement dropdown
    dataOverTimeDropdown = uicontrol('Parent',viewOptionsPanel, ...
        'Style','popupmenu', ...
        'String',{'None','Peak Locations','Instantaneous Velocity','Halfwidths','AUCs','Percent Above Background','Ring Area'}, ...
        'Units','normalized', ...
        'Position',[0.05 0.62 0.9 0.10], ...
        'Callback',{@data_over_time_selection});
    % save data plot button (enabled only when a plot is active)
    saveDataPlotButton = uicontrol('Parent',viewOptionsPanel, ...
        'Style','pushbutton', ...
        'String','Save Data Plot', ...
        'Units','normalized', ...
        'Position',[0.65 0.72 0.30 0.09], ...
        'Enable','off', ...
        'Tooltip','Save the current data-over-time plot as a TIFF in the same folder as Results_*.xlsx', ...
        'Callback',{@save_data_plot_callback});
    viewerSelectionTable = uicontrol('Parent',viewOptionsPanel, ...
        'Style','listbox', ...
        'String',{'Image Timepoints', 'scan movietalyzerResults_1'}, ...
        'Units','normalized', ...
        'Position',[0.05 0.05 0.9 0.54], ...
        'Callback',{@viewer_selection});

    % stack previewer 
    imagePanel = uipanel('Parent',guiCtrl, ...
        'Units','normalized', ...
        'Position',[0.375 0.30 0.58 0.65]);    
    imgAx = axes('Parent',imagePanel, ...
        'YTick',[],'XTick',[], ...
        'Units','normalized',...
        'Position',[0 0.1 1 0.9]);
    playButton = uicontrol('Parent',guiCtrl,...
        'Style','pushbutton', ...
        'String','▶', ...
        'Units','normalized', ...
        'Position',[0.375 0.95 0.05 0.05],...
        'Callback',{@play}); 
    labelTitle = uicontrol('Parent',guiCtrl, ...
        'Style','text', ...
        'String','Current Frame: 1/50', ...
        'Enable','on', ...
        'HorizontalAlignment','center',...
        'FontSize',12, ...
        'Units','normalized', ...
        'Position',[0.485 0.946 0.2 0.05]);
    channelSelection = uicontrol('Parent',guiCtrl, ...
        'Style','popupmenu', ...
        'String',{'channel1', 'channel2'}, ...
        'Units','normalized', ...
        'Position',[0.697 0.9425 0.1 0.05], ...
        'Value',1, ...
        'callback',{@channel_changed});
    movieFrameRate = uicontrol('Parent',guiCtrl,...
        'Style','pushbutton','String','Change Frame Rate', ...
        'Units','normalized', ...
        'Position',[0.822 0.95 0.134 0.05],...
        'Callback',{@change_frame_rate});

    sliderTimepoint = uicontrol('Parent',imagePanel, ...
        'Style','slide', ...
        'Units','normalized', ...
        'position',[0 0 1 0.07], ...
        'min',1,'max',50,...
        'val',1, ...
        'SliderStep', [1 1]/(50-1), ...
        'Enable','on');
    addlistener(sliderTimepoint,'ContinuousValueChange',@(hObject, event) update_image_timepoint(hObject, event));
    imageSliderDataPanel = uitable('Parent',guiCtrl, ...
    'ColumnName',{'channel1','channel2','channel3'}, ...
    'RowName', {'Peak Intens', 'Peak Locs', 'Halfwidths', 'AUCs', '% Abv Backg', 'Ring Area', 'Closing Vel','2/3 frame loc'},...
    'Units','normalized', ...
    'Position',[0.3525 0.02 0.35 .275]);
    
    % image queue panel
    imageQueuePanel = uipanel('Parent',guiCtrl, ...
        'Title', 'Image Queue Panel', ...
        'FontSize', 12, ...
        'Units','normalized', ...
        'Position',[0.7275 0.02 0.2475 0.275]);
    imageQueueTable = uicontrol('Parent',imageQueuePanel, ...
        'Style','listbox', ...
        'String',{'1'}, ...
        'Units','normalized', ...
        'Position',[0.05 0.1 0.9 0.8], ...
        'Callback',{@image_queue_selection});

    update_parameters(1)

    % populate image queue
    imageNames = cell(length(objarray));
    for l = 1:length(objarray)
        imageNames{l} = objarray(l).imageName;
    end
    set(imageQueueTable,'String',imageNames)
    
    function update_parameters(objIndex)
        currentObj = objIndex;
        obj = objarray(currentObj);
        if obj.nChannels == 1
            set(enterVelocityRangeC1,'String',num2str(obj.velocityStartStop(1,:)),...
                'UserData',num2str(obj.velocityStartStop(1,:)));
            advancedOptions.velocityStartStop(1,:)= obj.velocityStartStop(1,:);
            set(enterVelocityRangeC2,'Enable','off')
            set(enterVelocityRangeC3,'Enable','off')
        elseif obj.nChannels == 2
            if size(obj.velocityStartStop,1) == 1
                obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
            end
            set(enterVelocityRangeC1,'String',num2str(obj.velocityStartStop(1,:)),...
                'UserData',num2str(obj.velocityStartStop(1,:)));
            set(enterVelocityRangeC2,'String',num2str(obj.velocityStartStop(2,:)),...
                'UserData',num2str(obj.velocityStartStop(2,:)));
            advancedOptions.velocityStartStop = obj.velocityStartStop;
            set(enterVelocityRangeC2,'Enable','on')
            set(enterVelocityRangeC3,'Enable','off')
        elseif obj.nChannels == 3
            set(enterVelocityRangeC2,'Enable','on')
            set(enterVelocityRangeC3,'Enable','on')
        else
            error('only support images with no more than 3 channels')
        end

        [ParentFolderPath] = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
         % excelSavename = strcat('Results','_',num2str(movieIndex),'.xlsx');
         excelSavename = 'Results_1.xlsx';
         update_xlssheet(excelSavename);
        % xlsSheets = cell(1,5);
        % xlsSheets{1} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results_1.xlsx'),'Sheet', 'Peak Intensity','Range',rangeStart);
        % xlsSheets{2} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results_1.xlsx'), 'Sheet','Peak Locations','Range',rangeStart);
        % xlsSheets{3} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results_1.xlsx'), 'Sheet','Halfwidths','Range',rangeStart);
        % xlsSheets{4} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results_1.xlsx'), 'Sheet','AUCs','Range',rangeStart);
        % xlsSheets{5} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results_1.xlsx'), 'Sheet','Percent Above Background','Range',rangeStart);
        
        for m = 1:3
            for n = 1:8
                imageSliderDataPanel.Data{n, m} = ' ';
            end
        end

        referenceArray = [obj.cellArray{:,3}];
        % load in SphinctalyzerOutputs data structure
        pathToResults = strcat(ParentFolderPath,'/sphincRedo/sphinctalyzerResults.mat');
        SphincOutputs = load(pathToResults);
        % update channel names from the .mat file
        obj.channelNames = SphincOutputs.InputCells(:,1);
        objarray(currentObj) = obj;
        if max(referenceArray) == 0
            oneIndices = 1:obj.nChannels;
            SphinctalyzerOutputs = cell(obj.nChannels, obj.timepointEnd - obj.timepointStart + 1);
            for x = 1:obj.nChannels
                for p = obj.timepointStart:obj.timepointEnd
                    SphinctalyzerOutputs{x, p} = SphincOutputs.SphinctalyzerOutputs(p).(matlab.lang.makeValidName([obj.channelNames{x},'Outline']));
                end
            end
        else
            oneIndices = [];
            for y = 1:length(referenceArray)
                if referenceArray(y) == 1
                    oneIndices(end + 1) = y;
                end
                SphinctalyzerOutputs = cell(length(oneIndices), obj.timepointEnd - obj.timepointStart + 1);
                for x = 1:length(oneIndices)
                    for p = obj.timepointStart:obj.timepointEnd
                        SphinctalyzerOutputs{x, p} = SphincOutputs.SphinctalyzerOutputs(p).(matlab.lang.makeValidName([obj.channelNames{oneIndices(x)},'Outline']));
                    end
                end
            end
        end

        % update all the parameters
        set(darkBackground, 'Value', obj.darkBackground)
        set(enterNormalization, 'String', num2str(obj.normalization))
        set(enterNormalization,'UserData',obj.normalization)
        set(enterMicronsPerPixel,'String',num2str(obj.micronsPerPixel))
        set(enterMicronsPerPixel,'UserData',obj.micronsPerPixel)
        set(enterTimePerFrame,'String',num2str(obj.timePerFrame))
        set(enterTimePerFrame,'UserData',obj.timePerFrame)
        setChannelColor(obj.nChannels,obj.channelColors)

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

        % display image on the stack previewer
        iTimepoint = 1;
        obj = objarray(currentObj);
        set(sliderTimepoint,'min',1)
        set(sliderTimepoint,'max',obj.timepointEnd - obj.timepointStart +1)
        set(sliderTimepoint,'SliderStep',[1 1]/(obj.timepointEnd - obj.timepointStart))
        set(sliderTimepoint,'Value',1)
        I = bf_reader(iTimepoint, iChannel);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap)
        axis image equal
        drawnow
        update_image_data_panel(iTimepoint)
        set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
        
        channels = cell(obj.nChannels, 1);
        for i = 1:length(channels)
            channels{i, 1} = "channel" + i;
        end
        set(channelSelection,'String',channels)
        set(channelSelection,'Value',1)

        % set viewer selection list box 
        set(viewerSelectionTable,'Value',1)
        viewers = {'Image Timepoints', 'Circle Scan'};
        for i = 1:length(obj.moviePaths)
            viewers{end+1} = strcat('scan movietalyzerResults_',num2str(i));
        end
        set(viewerSelectionTable,'String',viewers)
        % find .avi files in sphincRedo directory to the moviefiles
        % attribute
        ParentFolderPath = fullfile(ParentFolderPath,'sphincRedo');
        validnames=dir(fullfile(ParentFolderPath, '*.avi'));
        validnames(strncmp({validnames.name}, '._', 2)) = [];  % remove macOS "._" metadata files
        if isempty(validnames)
            fprintf('No results movie is found in %s \n',ParentFolderPath)
            return
        end
        for i=1:size(validnames,1)
            if ~any(strcmp(obj.moviePaths, fullfile(validnames(i).folder,validnames(i).name)))
                obj.moviePaths = [obj.moviePaths; fullfile(validnames(i).folder,validnames(i).name)];
                current = get(viewerSelectionTable, 'String');
                current = [current; strcat('scan movietalyzerResults_', num2str(length(obj.moviePaths)))];
                set(viewerSelectionTable,'String',current)
                objarray(currentObj) = obj;
            end
        end 
        set(viewerSelectionTable,'Value',3) % enable the the first results
        viewer_selection(viewerSelectionTable)
    end

    function setChannelColor(nChannels,channelColors)
        for i = 1:nChannels
            channelColor = channelColors{i};
            if isequal(channelColor, [1 0 0])
                colorValue = 1;
            elseif isequal(channelColor, [0 0.6 0])
                colorValue = 2;
            elseif isequal(channelColor, [0 0 1])
                colorValue = 3;
            elseif isequal(channelColor, [0 1 1])
                colorValue = 4;
            elseif isequal(channelColor, [1 0 1])
                colorValue = 5;
            elseif isequal(channelColor, [1 1 0])
                colorValue = 6;
            elseif isequal(channelColor, [0 0 0])
                colorValue = 7;
            elseif isequal(channelColor, [1 1 1])
                colorValue = 8;
            end
            channelColorLabel(i) = uicontrol('Parent',moviePlotOptions, ...
                'Style','text', ...
                'String',strcat('Channel',num2str(i)), ...
                'FontSize',10, ...
                'Units','normalized', ...
                'Position',[0 h_start-0.585-(i*value_height*1.075) .45 value_height]);
            enterChannelColor(i) = uicontrol('Parent',moviePlotOptions, ...
                'Style','popupmenu', ...
                'String',{'red';'green';'blue';'cyan';'magenta';'yellow';'black';'white'}, ...
                'Units','normalized', ...
                'Position',[value_start-0.3 h_start-0.585-(i* value_height*1.025) value_width+0.30 value_height], ...
                'Value',colorValue, ...
                'Callback', {@cc_button, i});
        end
    end

    function viewer_selection(hObject, event)
        obj = objarray(currentObj);
        if hObject.Value > length(obj.moviePaths) + 2
            set(hObject,'Value',length(obj.moviePaths) + 2)
            return
        end
        if get(hObject, 'Value') >= 3
            mov = VideoReader(obj.moviePaths{get(hObject,'Value') - 2});
            selected_viewer = 3;
        elseif get(hObject, 'Value') == 2
            selected_viewer = 2;
        else
            selected_viewer = 1;
        end
        set(sliderTimepoint, 'Value', iTimepoint)
        I = readFunction{selected_viewer}(iTimepoint, iChannel);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        if selected_viewer == 1
            colormap(imgAx,obj.colormap)
        end
        %update the output table data and parameters associated with each
        %movie
        if selected_viewer == 3
            %update the data table
            hValue = hObject.Value;
            movieName = hObject.String{hValue};
            underscore_pos = strfind(movieName,"_");
            indexStart = underscore_pos+1;
            movieIndex =str2num(movieName(indexStart:end));
            excelSavename = strcat('Results','_',num2str(movieIndex),'.xlsx');
            update_xlssheet(excelSavename);
            %update the movie options
            update_movieOptions(excelSavename);
            % Close data plot and reset controls to default on results switch
            if ~isempty(dataPlotFig) && isvalid(dataPlotFig)
                close(dataPlotFig);
            end
            dataPlotFig = [];
            set(dataOverTimeDropdown,  'Value',   1);
            set(saveDataPlotButton,    'Enable', 'off');
            set(showFrameAxisCheckbox, 'Enable', 'off');
            set(showFrameAxisCheckbox, 'Value',   1);
            
        end
        axis image equal
        drawnow
        update_image_data_panel(iTimepoint)
        set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))

    end

    function update_image_timepoint(hObject, event)
        obj = objarray(currentObj);
        viewerSelectionTableValue = get(viewerSelectionTable, 'Value');
        if viewerSelectionTableValue >= 3
            mov = VideoReader(obj.moviePaths{viewerSelectionTableValue - 2});
            selected_viewer = 3;
        elseif viewerSelectionTableValue == 2
            selected_viewer = 2;
        else
            selected_viewer = 1;
        end
        iTimepoint = round(hObject.Value);
        I = readFunction{selected_viewer}(iTimepoint, iChannel);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        if selected_viewer == 1
            colormap(imgAx,obj.colormap)
        end
        axis image equal
        drawnow
        update_image_data_panel(iTimepoint)
        set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
        % update_table
    end
    
    function I = bf_reader(iTimepoint, iChannel)
        obj = objarray(currentObj);
        bfRederinfo = bfGetReader(fullfile(obj.imagePath, obj.imageName));
        bfRederinfo.setSeries(0);
        iPlane =  bfRederinfo.getIndex(0, iChannel - 1, iTimepoint+obj.timepointStart - 2) + 1;
        I = bfGetPlane(bfRederinfo, iPlane);
    end

    function I = movie_reader(iTimepoint, iChannel)
        I = read(mov, iTimepoint);
    end

    function I = circle_reader(iTimepoint, iChannel)
        obj = objarray(currentObj);
        firstChannelColor = obj.channelColors{oneIndices(1)};
        colorMap = [0,0,0; firstChannelColor(1) firstChannelColor(2) firstChannelColor(3)];
        firstChannelCircle = label2rgb(SphinctalyzerOutputs{1, obj.timepointStart + iTimepoint - 1} + 1, colorMap);
        if length(oneIndices) == 1
            I = firstChannelCircle;
        else
            secondChannelColor = obj.channelColors{oneIndices(2)};
            firstAndSecondChannelCircles = imoverlay(firstChannelCircle, imbinarize(SphinctalyzerOutputs{2, obj.timepointStart + iTimepoint - 1}), secondChannelColor);
            if length(oneIndices) == 2
                I = firstAndSecondChannelCircles;
            else
                thirdChannelColor = obj.channelColors{oneIndices(3)};
                allChannelCircles = imoverlay(firstAndSecondChannelCircles, SphinctalyzerOutputs{3, obj.timepointStart + iTimepoint - 1}, thirdChannelColor);
                I = allChannelCircles;
            end
        end
    end


    function play(hObject,eventdata)
        obj = objarray(currentObj);
        max = get(sliderTimepoint, 'max');
        pauseButton = uicontrol('Parent',guiCtrl,...
            'Style','pushbutton', ...
            'String','▐▐', ...
            'Units','normalized', ...
            'Position',[0.425 0.95 0.05 0.05],...
            'Callback',{@pause_callback});
        pauseS = false;
        while iTimepoint < max
            currentFrame = iTimepoint;
            if pauseS == false
                pause(1/frameRate)
                currentFrame = currentFrame + 1;
                set(sliderTimepoint,'Value',currentFrame)
                if get(viewerSelectionTable, 'Value') >= 3
                    mov = VideoReader(obj.moviePaths{get(viewerSelectionTable,'Value') - 2});
                    selected_viewer = 3;
                elseif get(viewerSelectionTable, 'Value') == 2
                    selected_viewer = 2;
                else
                    selected_viewer = 1;
                end
                I = readFunction{selected_viewer}(currentFrame, iChannel);
                imagesc(I,'Parent',imgAx);
                set(imgAx,'YTick',[],'XTick',[]);
                if selected_viewer == 1
                    colormap(obj.colormap)
                end
                axis image equal
                drawnow 
                set(labelTitle,'String',sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart, obj.nTimepoints));
                iTimepoint = currentFrame;
                update_image_data_panel(iTimepoint)
            else
                break
            end
        end
        delete(pauseButton)

        function pause_callback(hObject, event)
            pauseS = true;
            delete(hObject)
        end
    end
    
    function write_movie(hObject, event)
        writeMovieGUI = figure('Resize','off', ...
            'Color',defaultBackground', ...
            'Units','normalized', ...
            'Position',[0.4 0.475 0.2 0.09], ...
            'Visible','on',...
            'MenuBar','none', ...
            'name','Write Movie', ...
            'NumberTitle','off');
        label = uicontrol('Parent',writeMovieGUI, ...
            'Style','text', ...
            'String','Create a new movie file or overwrite existing movie file?', ...
            'Enable','on', ...
            'HorizontalAlignment','center',...
            'FontSize',12, ...
            'Units','normalized', ...
            'Position',[0 0.7 1 0.2]);
        createNewButton = uicontrol('Parent',writeMovieGUI, ...
            'Style','pushbutton', ...
            'String','Create New', ...
            'FontSize',10, ...
            'Units','normalized', ...
            'Position',[0.05 0.1 .4 .2], ...
            'Callback',{@create_new_movie});
        overwriteExistingButton = uicontrol('Parent',writeMovieGUI, ...
            'Style','pushbutton', ...
            'String','Overwrite Existing', ...
            'FontSize',10, ...
            'Units','normalized', ...
            'Position',[0.55 0.1 .4 .2], ...
            'Callback',{@overwrite_existing_movie});
        
        function create_new_movie(hObject, event)
            delete(writeMovieGUI)
            obj = objarray(currentObj);
            [ParentFolderPath] = fileparts(obj.filePath);
            [ParentFolderPath] = fileparts(ParentFolderPath);
            movieIndex = length(obj.moviePaths)+1;
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
                movieIndex, ...
                obj.imageName,...
                obj.velocityStartStop,...
                advancedOptions)
            newMoviePath = strrep(obj.moviePaths{1},'Results_1',strcat('Results_',(num2str(length(obj.moviePaths) + 1))));
            obj.moviePaths = [obj.moviePaths; newMoviePath];
            current = get(viewerSelectionTable, 'String');
            current = [current; strcat('scan movietalyzerResults_', num2str(length(obj.moviePaths)))];
            set(viewerSelectionTable,'String',current)
            set(viewerSelectionTable,'Value',length(obj.moviePaths) + 2)
            objarray(currentObj) = obj;
            
            % update the viewer
            iTimepoint = 1;        
            mov = VideoReader(obj.moviePaths{length(obj.moviePaths)});
            selected_viewer = 3;
            set(sliderTimepoint, 'Value', iTimepoint)
            I = readFunction{selected_viewer}(iTimepoint, iChannel);
            imagesc(I,'Parent',imgAx);
            set(imgAx,'YTick',[],'XTick',[]);
            if selected_viewer == 1
                colormap(imgAx,obj.colormap)
            end
            axis image equal
            drawnow
            excelSavename = strcat('Results','_',num2str(movieIndex),'.xlsx');
            update_xlssheet(excelSavename);
            update_image_data_panel(iTimepoint)
            set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
        end

        function overwrite_existing_movie(hObject, event)
            delete(writeMovieGUI)
            obj = objarray(currentObj);
            overwriteMovieGUI = figure('Resize','off', ...
            'Color',defaultBackground', ...
            'Units','normalized', ...
            'Position',[0.4 0.3 0.2 0.4], ...
            'Visible','on',...
            'MenuBar','none', ...
            'name','Write Movie', ...
            'NumberTitle','off');
            overwriteLabel = uicontrol('Parent',overwriteMovieGUI, ...
                'Style','text', ...
                'String','Choose a movie file to overwrite:', ...
                'Enable','on', ...
                'HorizontalAlignment','center',...
                'FontSize',12, ...
                'Units','normalized', ...
                'Position',[0 0.8 1 0.2]);
            hsr = uibuttongroup('parent',overwriteMovieGUI, ...
                'title','Movie Files', ...
                'visible','on', ...
                'FontSize',12, ...
                'Units','normalized', ...
                'Position',[0.05 0.17 0.9 0.75]);
            for u = 1:length(obj.moviePaths)
                name = strcat('scan movietalyzerResults_',num2str(u));
                movieFileButton(u) = uicontrol('Style','radiobutton', ...
                    'String',name, ...
                    'Units','normalized',...
                    'pos',[0.1 1-(u*0.085) 0.8 0.085], ...
                    'parent',hsr, ...
                    'HandleVisibility','on', ...
                    'FontSize',10, ...
                    'Enable','on');
            end
            okButton = uicontrol('Parent',overwriteMovieGUI, ...
            'Style','pushbutton', ...
            'String','Ok', ...
            'FontSize',10, ...
            'Units','normalized', ...
            'Position',[0.15 0.05 .7 .1], ...
            'Callback',{@overwrite});

            function overwrite(hObject, event)
                movieName = get(get(hsr,'SelectedObject'),'String');
                delete(overwriteMovieGUI)
                movieIndex = movieName(end);
                obj = objarray(currentObj);
                [ParentFolderPath] = fileparts(obj.filePath);
                [ParentFolderPath] = fileparts(ParentFolderPath);
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
                    movieIndex, ...
                    obj.imageName,...
                    obj.velocityStartStop,...
                    advancedOptions)

                % update the viewer
                set(viewerSelectionTable,'Value',str2double(movieIndex) + 2)
                iTimepoint = 1;        
                mov = VideoReader(obj.moviePaths{get(viewerSelectionTable,'Value') - 2});
                selected_viewer = 3;
                set(sliderTimepoint, 'Value', iTimepoint)
                I = readFunction{selected_viewer}(iTimepoint, iChannel);
                imagesc(I,'Parent',imgAx);
                set(imgAx,'YTick',[],'XTick',[]);
                if selected_viewer == 1
                    colormap(imgAx,obj.colormap)
                end
                axis image equal
                drawnow
                excelSavename = strcat('Results','_',num2str(movieIndex),'.xlsx');
                update_xlssheet(excelSavename);
                update_image_data_panel(iTimepoint)
                set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
            end
        end
    end

    function write_movies(~,~)
        numImages = size(objarray,2);
        processedPaths = cell(numImages,1);
        for imageIndex = 1: numImages
            moviePath = objarray(imageIndex).moviePaths{1};
            foldermarkerIndex = strfind(moviePath,'sphincRedo');
            postPath = moviePath(1:foldermarkerIndex-1);
            processedPaths{imageIndex} = postPath;
        end
        % update previously processed images
        answerPost = questdlg('Overwirte the Resluts_1 using pararmeters saved in parameters_post.xlsx file or Results_1.xlsx file?', ...
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

    end
    function save_postParameters(~,~)
        % add a question dialog to update parameters for current movie or common parameters to all movies
        saveCommonFlag = [];
        saveID = currentObj;
        answerPostSave = questdlg('Save current post-processing parameters for current movie or all movies in parameters_post.xlsx file?', ...
            'Updating post-processing parameters for one movie or all movies ', ...
            'Save current','Save common parameters for all','Save current');
        % Handle response
        switch answerPostSave
            case 'Save current'
                saveCommonFlag = 0;
                obj_current = objarray(currentObj);
                moviePath = obj_current.moviePaths{1};
                save_post_parameters(obj_current,advancedOptions,saveCommonFlag, moviePath);
            case 'Save common parameters for all'
                disp('Common post-processing parameters will be updated for all movies')
                % specify the common parameters
                % 1: Channel Colors
                % 2: Axes Names
                % 3: DarkBackgroundFlag
                % 4: SecondsPerFrame
                % 5: Normalization
                % 6: Legend Location
                % 7: MicronsPerPixel
                % 8: xMinStepMax
                % 9: yMinStepMax
                % 10: File Index
                % 11: Image Filename
                % 12: Results Folder
                % 13: velocityStartStop
                % 14: peak searching radius
                % 15: closing check point
                % 16: Channel Names
                saveCommonFlag = 1;
                obj_current = objarray(currentObj);
                for objID = 1:length(objarray)
                    obj = objarray(objID);
                    moviePath = obj.moviePaths{1};
                    save_post_parameters(obj_current,advancedOptions,saveCommonFlag,moviePath);
                end
        end



        
    end
    
    %% Callbacks
    function change_x_axis(hObject, event)
        obj = objarray(currentObj);
        prompts = {'Enter x-axis title:','Enter minimum x value:','Enter x step value:', 'Enter maximum x value:'};
        axesNames = obj.axesNames;
        xMinStepMax = obj.xMinStepMax;
        dims = [1 35];
        definput = {axesNames{1}, num2str(xMinStepMax(1)), num2str(xMinStepMax(2)), num2str(xMinStepMax(3))};
        dlgtitle = 'Edit X Axis';
        answer = inputdlg(prompts,dlgtitle,dims, definput);
        if ~isempty(answer)
            if ~isempty(answer{1})
                axesNames{1} = answer{1};
                obj.axesNames = axesNames;
                objarray(currentObj) = obj;
            end
            for s=2:4
                if ~isempty(answer{s})
                    if ~isnan(str2double(answer{s}))
                        xMinStepMax(s-1) = str2double(answer{s});
                    else
                        errordlg('Please enter a number for the Min, Step, and Max values')
                    end
                end
            end
        end
        if ~isempty(xMinStepMax(1):xMinStepMax(2):xMinStepMax(3))
            obj.xMinStepMax = xMinStepMax;
            objarray(currentObj) = obj;
        else
            errordlg('Please enter a viable Min:Step:Max.')
        end
    end
    
    function change_y_axis(hObject, event)
        obj = objarray(currentObj);
        prompts = {'Enter y-axis title:','Enter minimum y value:','Enter y step value:', 'Enter maximum y value:'};
        axesNames = obj.axesNames;
        yMinStepMax = obj.yMinStepMax;
        dims = [1 35];
        definput = {axesNames{2}, num2str(yMinStepMax(1)), num2str(yMinStepMax(2)), num2str(yMinStepMax(3))};
        dlgtitle = 'Edit Y Axis';
        answer = inputdlg(prompts,dlgtitle,dims, definput);
        if ~isempty(answer)
            if ~isempty(answer{1})
                axesNames{2} = answer{1};
                obj.axesNames = axesNames;
                objarray(currentObj) = obj;
            end
            for i=2:4
                if ~isempty(answer{i})
                    if ~isnan(str2double(answer{i}))
                        yMinStepMax(i-1) = str2double(answer{i});
                    else
                        errordlg('Please enter a number for the Min, Step, and Max values')
                    end
                end
            end
        end
        if ~isempty(yMinStepMax(1):yMinStepMax(2):yMinStepMax(3))
            obj.yMinStepMax = yMinStepMax;
            objarray(currentObj) = obj;
        else
            errordlg('Please enter a viable Min:Step:Max.')
        end
    end

    function darkBackgroundCbx(hObject, event)
        objarray(currentObj).darkBackground = get(hObject, 'Value');
    end

    function get_textbox_normalization(enterNormalization, event)
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
        obj.normalization = usr_input;
        axesNames = obj.axesNames;
        switch usr_input
            case 1
                axesNames{2} = getDefaultYAxisTitle();
                obj.yMinStepMax = [-0.1 0.1 1.1];
            case 2
                axesNames{2} = 'Fold Over Background';
                obj.yMinStepMax = [-1 1 6];
            case 3
                axesNames{2} = 'Fluorescence Value';
                obj.yMinStepMax = [0 500 4100];
            otherwise
                axesNames{2} = getDefaultYAxisTitle();
                obj.yMinStepMax = [-0.1 0.1 1.1];
        end
        obj.axesNames = axesNames;
        objarray(currentObj) = obj;
        set(enterNormalization, 'UserData', usr_input)
    end

    function get_textbox_micronsPerPixel(enterMicronsPerPixel, event)
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
        obj.micronsPerPixel = usr_input;
        axesNames = obj.axesNames;
        switch usr_input
            case 1
                axesNames{1} = 'Distance (pixels) from wound center';
                obj.xMinStepMax = xMinStepMax;
                objarray(currentObj) = obj;
            otherwise
                axesNames{1} = 'Position (Microns) relative to wound center';
                xMinStepMax = usr_input * xMinStepMax;
                obj.xMinStepMax = xMinStepMax;
                objarray(currentObj) = obj;
        end
        obj.axesNames = axesNames;
        objarray(currentObj) = obj;
        set(enterMicronsPerPixel, 'UserData', usr_input)
    end

    function get_timePerFrame(hObject, event)
        usr_input = get(hObject,'String');
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
        objarray(currentObj).timePerFrame = usr_input;
        obj = objarray(currentObj);
    end
    
    function get_legend_location(hObject, event)
        legend_locations = {'NorthWest','NorthEast','SouthWest','SouthEast'};
        selected_legend_location = legend_locations{get(hObject, 'Value')};
        objarray(currentObj).legendLocation = selected_legend_location;
    end
% call back fuction to changeChannelNames
    function changeChannelNames_callback(~, ~)
        % prompt the user for new channel name
        obj = objarray(currentObj);
        nChannels = obj.nChannels;
         % get the saved channle names from the results .mat file 
        ParentFolderPath = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        pathToResults = strcat(ParentFolderPath,'/sphincRedo/sphinctalyzerResults.mat');
        SphincOutputs_load = load(pathToResults,'InputCells');
        cellArray = SphincOutputs_load.InputCells;
        % cellArray = SphincOutputs_load.InputCells;
        oldChannelNames = cellArray(:,1);
        %channel name change dialog window 
        prompts = cell(obj.nChannels, 1);
        for i = 1:length(prompts)
            prompts{i} = "Enter name of channel " + i + ":";
        end
        dims = [1 35];
        definput = cell(nChannels, 1);
        if nChannels == 1
            definput = {cellArray{1, 1}};
        elseif nChannels == 2
            definput = {cellArray{1, 1}, cellArray{2, 1}};
        elseif nChannels == 3
            definput = {cellArray{1, 1}, cellArray{2, 1}, cellArray{3, 1}};
        end
        dlgtitle = 'Edit Channel Names';
        answer = inputdlg(prompts,dlgtitle,dims,definput);
        unique_channels = unique(answer);
        if numel(unique_channels) < numel(answer)
            msgbox('Do not accept identical channel names. Channel name change failed')
            return
        end
        if ~isempty(answer)
            % update the channel name
            for iC = 1:nChannels
                if ~isempty(answer{iC})
                    obj.cellArray{iC, 1} = answer{iC};
                    obj.channelNames{iC} = answer{iC};
                else
                    fprintf('Name of Channel %d is not entered.Channel %d name NOT changed \n', iC, iC)
                end
            end
        else
            disp('Channel name NOT changed ')
        end
        newChannelNames = obj.cellArray(:,1);
        %find the current channel names in the .mat file
        SphinctalyzerOutputs_update = updateChannelNamesInResultsMatFile(obj,oldChannelNames,newChannelNames);
        if ~isempty(SphinctalyzerOutputs_update)
            SphinctalyzerOutputs = SphinctalyzerOutputs_update;
            objarray(currentObj) = obj; 
        else
            disp('Channel name is not changed, results mat file is not changed')
        end
    end
    
    function cc_button(hObject, event, channelNumber)
        obj = objarray(currentObj);
        colors = {[1 0 0],[0 0.6 0],[0 0 1],[0 1 1],[1 0 1],[1 1 0],[0 0 0],[1 1 1]};
        chosenColor = colors{get(hObject, 'Value')};
        currentColors = obj.channelColors;
        currentColors{channelNumber} = chosenColor;
        obj.channelColors = currentColors;
        objarray(currentObj) = obj;
    end
    
    function change_color_map(hObject, event)
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
        set(viewerSelectionTable,'Value',1)
        selected_viewer = 1;
        I = readFunction{selected_viewer}(iTimepoint, iChannel);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap)
        axis image equal
        drawnow
        set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
    end

    function get_searchingRadius(hObject,event)
        usr_input = get(hObject,'String');
        if isnan(str2double(usr_input))
            errordlg('Please enter a number.')
            set(enterSearchingRadius,'String',num2str(get(enterSearchingRadius,'UserData')))
            return
        end
        usr_input = str2double(usr_input);
        if usr_input < 0
            errordlg('Please enter a positive number.')
            set(enterSearchingRadius,'String',num2str(get(enterSearchingRadius,'UserData')))
            return
        end
        % objarray(currentObj).peakSearchingRadius = usr_input;
        enterSearchingRadius.UserData = usr_input;
        advancedOptions.peakSearchingRadius = usr_input;
    end
    function get_velocityRangeC1(hObject,event)
        usr_input = get(hObject,'String');
        if any([isnan(str2num(usr_input)), size(str2num(usr_input),2)~=2])
            errordlg('Please enter a number pair.')
            set(enterVelocityRangeC1,'String',num2str(get(enterVelocityRangeC1,'UserData')))
            return
        end
        usr_input = str2num(usr_input);
        if usr_input(1) < 1 || usr_input(2) < 1
            errordlg('Please enter a positive number pair.')
            set(enterVelocityRangeC1,'String',num2str(get(enterVelocityRangeC1,'UserData')))
            return
        end
        if usr_input(2) <= usr_input(1)
            errordlg('The velocity end frame must be after the start frame.')
            set(enterVelocityRangeC1,'String',num2str(get(enterVelocityRangeC1,'UserData')))
            return
        end
        % objarray(currentObj).velocityRange_C1 = usr_input;
        enterVelocityRangeC1.UserData = usr_input;
        advancedOptions.velocityStartStop(1,:) = usr_input; 
        disp('veloctiy range of channel 1 is changed')
    end
    function get_velocityRangeC2(hObject,event)
        usr_input = get(hObject,'String');
        if any([isnan(str2num(usr_input)), size(str2num(usr_input),2)~=2])
            errordlg('Please enter a number pair.')
            set(enterVelocityRangeC2,'String',num2str(get(enterVelocityRangeC2,'UserData')))
            return
        end
        usr_input = str2num(usr_input);
        if usr_input(1) < 1 || usr_input(2) < 1
            errordlg('Please enter a positive number pair.')
            set(enterVelocityRangeC2,'String',num2str(get(enterVelocityRangeC2,'UserData')))
            return
        end
        if usr_input(2) <= usr_input(1)
            errordlg('The velocity end frame must be after the start frame.')
            set(enterVelocityRangeC2,'String',num2str(get(enterVelocityRangeC2,'UserData')))
            return
        end
        % objarray(currentObj).velocityRange_C1 = usr_input;
        enterVelocityRangeC2.UserData = usr_input;
        advancedOptions.velocityStartStop(2,:) = usr_input;
        disp('veloctiy range of channel 2 is changed')
    end

    function get_velocityRangeC3(hObject,event)
        usr_input = get(hObject,'String');
        if any([isnan(str2num(usr_input)), size(str2num(usr_input),2)~=2])
            errordlg('Please enter a number pair.')
            set(enterVelocityRangeC3,'String',num2str(get(enterVelocityRangeC3,'UserData')))
            return
        end
        usr_input = str2num(usr_input);
        if usr_input(1) < 1 || usr_input(2) < 1
            errordlg('Please enter a positive number pair.')
            set(enterVelocityRangeC3,'String',num2str(get(enterVelocityRangeC3,'UserData')))
            return
        end
        if usr_input(2) <= usr_input(1)
            errordlg('The velocity end frame must be after the start frame.')
            set(enterVelocityRangeC3,'String',num2str(get(enterVelocityRangeC3,'UserData')))
            return
        end
        % objarray(currentObj).velocityRange_C1 = usr_input;
        enterVelocityRangeC3.UserData = usr_input;
        advancedOptions.velocityStartStop(3,:) = usr_input;
        disp('veloctiy range of channel 3 is changed')
    end

    function get_closingCheckpoint(hObject,event)
        usr_input = get(hObject,'String');
        if any([isnan(str2num(usr_input)),str2num(usr_input)<0, str2num(usr_input)>1])
            errordlg('Please enter number(s) between 0-1.')
            set(enterClosingCheckpoint,'String',num2str(get(enterClosingCheckpoint,'UserData')))
            return
        end
        usr_input = str2num(usr_input);
        enterClosingCheckpoint.UserData = usr_input;
        advancedOptions.closingCheckpoint = usr_input;
        fprintf('Check point for wound closing %s added \n',num2str(usr_input,'% 4.3f'));
    end

    function get_closingCheckBasis(hObject,event)
        closingCheckBases = {'position','area'};
        advancedOptions.closingCheckBasis = closingCheckBases{get(hObject,'Value')};
        fprintf('Closing check is based on the %s \n',advancedOptions.closingCheckBasis);
    end

    function channel_changed(hObject, event)
        iChannel = hObject.Value;
        obj = objarray(currentObj);
        set(viewerSelectionTable,'Value',1)
        selected_viewer = 1;
        I = readFunction{selected_viewer}(iTimepoint, iChannel);
        imagesc(I,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,obj.colormap)
        axis image equal
        drawnow
        set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
    end
    
    function change_frame_rate(hObject, event)
        prompt = 'Enter frame rate:';
        definput = {num2str(frameRate)};
        dims = [1 35];
        dlgtitle = 'Change Frame Rate';
        answer = inputdlg(prompt,dlgtitle,dims, definput);
        if ~isempty(answer)
            if ~isnan(str2double(answer{1}))
                if str2double(answer{1}) > 0
                    frameRate = str2double(answer{1});
                else
                    errordlg('Please enter a positive number.')
                end
            else
                errordlg('Please enter a number.')
            end
        end
    end

    function image_queue_selection(hObject, event)
        % If another image selected, update_parameter(objIndex)
        if hObject.Value > length(objarray)
            set(hObject,'Value',length(objarray))
            return
        end
        currentObj = get(hObject, 'Value');
        update_parameters(currentObj)
    end
  
    function update_image_data_panel(currentTimepoint)
        obj = objarray(currentObj);
        %initialize the imageSliderDataPanel
        imageSliderDataPanel.Data=[];
        imageSliderDataPanel.RowName= imageSliderDataPanel.RowName(1:7); % only keep the first 7 row names
        % the slider position counts from the first analyzed frame; the sheets
        % have one column per frame, numbered in xlsFrameNums
        currentFrame = obj.timepointStart + currentTimepoint - 1;
        frameColumn = find(xlsFrameNums == currentFrame, 1);
        % rows 1-5: Peak Intensity, Peak Locations, Halfwidths, AUCs,
        % Percent Above Background (xlsSheets 1-5); row 6: Ring Area (xlsSheets 7)
        sheetIndexes = [1 2 3 4 5 7];
        for m = 1:obj.nChannels
            for n = 1:numel(sheetIndexes)
                if isempty(frameColumn) || numel(xlsSheets) < sheetIndexes(n) || isempty(xlsSheets{sheetIndexes(n)})
                    imageSliderDataPanel.Data{n, m} = 'N/A'; % e.g. no Ring Area in results from earlier versions
                    continue
                end
                sheet = xlsSheets{sheetIndexes(n)};
                try
                    imageSliderDataPanel.Data{n, m} = sheet(m, frameColumn);
                catch exp1
                    fprintf(' %s \n %s of frame %d is empty \n',exp1.message,imageSliderDataPanel.RowName{n},currentFrame)
                    imageSliderDataPanel.Data{n, m} = 'N/A';
                end
            end
        end

        % calculate wound closing velocity
        closingVelocityLocation = xlsSheets{6};
        % calculate the nearest frame index corresponding to 2/3, 1/2, 1/3
        % of closing location
        for b = 1:obj.nChannels
            woundClosingVelocity = closingVelocityLocation{3,b+1}; %* obj.micronsPerPixel;
            if ismissing(woundClosingVelocity)
                woundClosingVelocity = 'N/A';
            end
            imageSliderDataPanel.Data{7, b} = woundClosingVelocity;
            checkpoint_num = size(closingVelocityLocation,1)-3;
            for cp = 1:checkpoint_num
                closingVelocityLocation_load = closingVelocityLocation{3+cp,b+1};

                if ismissing(closingVelocityLocation_load)
                    closingVelocityLocation_load = 'N/A';
                end
                imageSliderDataPanel.Data{7+cp, b} = closingVelocityLocation_load;
                if b == 1
                     imageSliderDataPanel.RowName{7+cp} = strrep(closingVelocityLocation{3+cp,1},'closing position','close');
                end
            end
        end

    end

    function update_xlssheet(excelSavename)
        obj = objarray(currentObj);
        [ParentFolderPath] = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        currentExcelSavename = excelSavename;  % keep save name in sync
        try
            xlsPath = fullfile(ParentFolderPath,'sphincRedo',excelSavename);
            % Read each data sheet starting from column B (not C) so that column B
            % (the explicitly-written frame-number column, 1..frameInrangeMax) acts as
            % an anchor.  readmatrix auto-detects the used range; if we start from C2,
            % it skips leading empty rows (frames before the analysis window begin),
            % producing a rawSheet that is shorter than xlsFrameNums.  Starting from B2
            % forces the full rectangle to be read, including NaN-padded leading rows.
            %   rawFull columns: 1 = frame numbers  2..end = channel data (+instant cols)
            sheetNames = {'Peak Intensity','Peak Locations','Halfwidths','AUCs','Percent Above Background'};
            xlsSheets = cell(1,6);
            rawFull = [];
            for iS = 1:5
                rawFull = readmatrix(xlsPath, 'Sheet', sheetNames{iS}, 'Range', 'B2');
                xlsSheets{iS} = rawFull(:, 2:end)';   % nCh (+ instant cols) x nFrames
            end
            % xlsFrameNums is the frame-number column (col B) — identical across all sheets
            rawFN = rawFull(:, 1);
            xlsFrameNums = rawFN(~isnan(rawFN))';   % row vector [1, 2, ..., frameInrangeMax]
            xlsSheets{6} = readcell(xlsPath, 'Sheet','Closing Velocity and Location','Range','B2');
            % Ring Area sheet is not in results created by earlier versions
            xlsSheets{7} = [];
            if any(strcmp(sheetnames(xlsPath),'Ring Area'))
                rawRingArea = readmatrix(xlsPath, 'Sheet', 'Ring Area', 'Range', 'B2');
                xlsSheets{7} = rawRingArea(:, 2:end)';
            end
            % Channel names from row 1, columns C onwards
            nCh = obj.nChannels;
            endColLetter = char('A' + 1 + nCh);  % nCh=1→C, nCh=2→D, nCh=3→E
            rawHeader = readcell(xlsPath, 'Sheet', 'Peak Locations', 'Range', ['C1:' endColLetter '1']);
            xlsChannelNames = cell(1, nCh);
            for iCh = 1:nCh
                if iCh <= numel(rawHeader) && (ischar(rawHeader{iCh}) || isstring(rawHeader{iCh}))
                    xlsChannelNames{iCh} = char(rawHeader{iCh});
                else
                    xlsChannelNames{iCh} = sprintf('Channel %d', iCh);
                end
            end
            % refresh_data_plot() is called by the caller after update_movieOptions
            % so that advancedOptions and channel metadata are up to date first
        catch exp_xlsread
            suggestonSTR = sprintf(['The results reading didnot go through \n' ...
                '    This file is probably created by an earlier version. \n' ...
                '    To proceed, press the Post-Process button in the Main window, and choose the option to create new output files \n'],fullfile(ParentFolderPath,'sphincRedo',excelSavename))
            %delete(guiCtrl)
            msgbox(sprintf('Error message: %s \n   %s \n',exp_xlsread.message, suggestonSTR))


        end

    end
    function update_movieOptions(excelSavename)

        %load movie parameters from the results excel file
        obj = objarray(currentObj);
        [ParentFolderPath] = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        movieOptions = readcell(fullfile(ParentFolderPath,'sphincRedo',excelSavename),'Sheet','parameters');
        % parameters_post{1,1} = 'Channel Colors'; 
        % nColors = length(channelColors);
        % for i = 1:nColors
        %     parameters_post{1,i+1} = mat2str(channelColors{i});
        % end
        % parameters_post{2,1} = 'Axes Names';
        % nAxesNames = length(axesNames);
        % for i = 1:nAxesNames
        %     parameters_post{2,i+1} = axesNames{i};
        % end
        % parameters_post{3,1} = 'DarkBackgroundFlag'; parameters_post{3,2} = darkBackgroundFlag;
        % parameters_post{4,1} = 'SecondsPerFrame'; parameters_post{4,2} = secondsPerFrame;
        % parameters_post{5,1} = 'Normalization'; parameters_post{5,2} = normalization;
        % parameters_post{6,1} = 'Legend Location'; parameters_post{6,2} = legendLocation;
        % parameters_post{7,1} = 'MicronsPerPixel'; parameters_post{7,2} = micronsPerPixel;
        % parameters_post{8,1} = 'xMinStepMax'; parameters_post{8,2} = mat2str(xMinStepMax);
        % parameters_post{9,1} = 'yMinStepMax'; parameters_post{9,2} = mat2str(yMinStepMax);
        % parameters_post{10,1} = 'File Index'; parameters_post{10,2} = num;
        % parameters_post{11,1} = 'Image Filename'; parameters_post{11,2} = imageFileName;
        % parameters_post{12,1} = 'Results Folder'; parameters_post{12,2} = savepath;
        % update all the parameters
        obj.darkBackground = movieOptions{3,2};
        obj.normalization = movieOptions{5,2};
        obj.legendLocation = movieOptions{6,2};
        obj.micronsPerPixel = movieOptions{7,2};
        obj.timePerFrame = movieOptions{4,2};
        for iC = 1:obj.nChannels
            obj.channelColors{iC} = str2num(movieOptions{1,iC+1});
        end
        obj.axesNames = movieOptions(2,2:3);
        obj.xMinStepMax = positiveXMinStepMax(str2num(movieOptions{8,2}));
        obj.yMinStepMax = str2num(movieOptions{9,2});
        velocityRanges = {enterVelocityRangeC1 enterVelocityRangeC2 enterVelocityRangeC3};
        if size(movieOptions,1) == 13
              if size(obj.velocityStartStop,1) == 1
                obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
              end
              advancedOptions.velocityStartStop =obj.velocityStartStop;
              advancedOptions.peakSearchingRadius = defaultPeakSearchingRadius;
              advancedOptions.closingCheckpoint= [0.667 0.500 0.333];
              advancedOptions.closingCheckBasis = 'position';
        elseif size(movieOptions,1) >= 15
            for iC = 1:obj.nChannels
                advancedOptions.velocityStartStop(iC,:) = str2num(movieOptions{13,1+iC});
            end
            advancedOptions.peakSearchingRadius = movieOptions{14,2};
            try
                advancedOptions.closingCheckpoint = str2num(movieOptions{15,2});
            catch
                advancedOptions.closingCheckpoint = movieOptions{15,2};
            end
            fprintf('number of closing checkpoint(s) is %d \n', size(advancedOptions.closingCheckpoint,2))
            if size(movieOptions,1) >= 17
                advancedOptions.closingCheckBasis = closingCheckBasisOption(movieOptions{17,2});
            else
                advancedOptions.closingCheckBasis = 'position'; % results from earlier versions
            end

        end
        if obj.nChannels == 1
            set(enterVelocityRangeC2,'Enable','off')
            set(enterVelocityRangeC3,'Enable','off')
        elseif obj.nChannels == 2
            set(enterVelocityRangeC2,'Enable','on')
            set(enterVelocityRangeC3,'Enable','off')
        elseif obj.nChannels == 3
            set(enterVelocityRangeC2,'Enable','on')
            set(enterVelocityRangeC3,'Enable','on')
        else
            error('only support images with no more than 3 channels')
        end

        for iC = 1:obj.nChannels
            set(velocityRanges{iC},'String',num2str(advancedOptions.velocityStartStop(iC,:)),...
                'UserData',advancedOptions.velocityStartStop(iC,:));
        end
        set(enterSearchingRadius,'String',num2str(advancedOptions.peakSearchingRadius),...
            'UserData',advancedOptions.peakSearchingRadius);
        set(enterClosingCheckpoint,'String',num2str(advancedOptions.closingCheckpoint,' %4.3f'),...
            'UserData',advancedOptions.closingCheckpoint);
        set(selectClosingCheckBasis,'Value',1+strcmp(advancedOptions.closingCheckBasis,'area'));

        objarray(currentObj) = obj;
        set(darkBackground, 'Value', obj.darkBackground);
        set(enterNormalization, 'String', num2str(obj.normalization));
        set(enterNormalization,'UserData',obj.normalization);
        set(enterMicronsPerPixel,'String',num2str(obj.micronsPerPixel));
        set(enterMicronsPerPixel,'UserData',obj.micronsPerPixel);
        set(enterTimePerFrame,'String',num2str(obj.timePerFrame));
        set(enterTimePerFrame,'UserData',obj.timePerFrame);
        legendValue = find(strcmp(enterLegendLocation.String,obj.legendLocation)==1);
        set(enterLegendLocation,'Value',legendValue);   
        setChannelColor(obj.nChannels,obj.channelColors);
    end

    % ---- Data over time callbacks ----------------------------------------

    function data_over_time_selection(hObject, ~)
        if hObject.Value == 1  % "None" selected
            if ~isempty(dataPlotFig) && isvalid(dataPlotFig)
                close(dataPlotFig);
            end
            dataPlotFig = [];
            set(saveDataPlotButton, 'Enable', 'off');
            set(showFrameAxisCheckbox, 'Enable', 'off');
        else
            show_data_over_time_plot();
            set(saveDataPlotButton, 'Enable', 'on');
            set(showFrameAxisCheckbox, 'Enable', 'on');
        end
    end

    function show_data_over_time_plot()
        obj = objarray(currentObj);
        dropVal = dataOverTimeDropdown.Value;
        nCh = obj.nChannels;

        % Map dropdown value to data source and axis labels
        switch dropVal
            case 2  % Peak Locations
                rawSheet   = xlsSheets{2};
                yLabelStr  = 'Peak Location (\mum from wound center)';
                xLabelStr  = 'Time (s) After Zone Appearance';
                useVelRange = true;
                computeDiff = false;
            case 3  % Instantaneous Velocity
                rawSheet   = xlsSheets{2};
                yLabelStr  = 'Instantaneous Velocity (\mum/s)';
                xLabelStr  = 'Time (s) After Zone Appearance';
                useVelRange = true;
                computeDiff = true;
            case 4  % Halfwidths
                rawSheet   = xlsSheets{3};
                yLabelStr  = 'Half-width (\mum)';
                xLabelStr  = 'Time (s) After Zone Appearance';
                useVelRange = true;
                computeDiff = false;
            case 5  % AUCs
                rawSheet   = xlsSheets{4};
                yLabelStr  = 'AUC (\mum^2)';
                xLabelStr  = 'Time (s) After Zone Appearance';
                useVelRange = true;
                computeDiff = false;
            case 6  % Percent Above Background
                rawSheet   = xlsSheets{5};
                yLabelStr  = '% Above Background';
                xLabelStr  = 'Time (s)';
                useVelRange = false;
                computeDiff = false;
            case 7  % Ring Area
                if numel(xlsSheets) < 7 || isempty(xlsSheets{7})
                    msgbox(['No ring area in this results file. It was probably created by an earlier version; ' ...
                        'write the movie again to add the ring area.'],'Ring Area')
                    set(dataOverTimeDropdown,'Value',1);
                    return
                end
                rawSheet   = xlsSheets{7};
                yLabelStr  = 'Ring Area (\mum^2)';
                xLabelStr  = 'Time (s) After Zone Appearance';
                useVelRange = true;
                computeDiff = false;
            otherwise
                return
        end

        % Reuse the existing figure window if open; otherwise create it.
        % Delete all children (axes + their listeners) for a clean redraw.
        if isempty(dataPlotFig) || ~isvalid(dataPlotFig)
            screenSize     = get(0, 'ScreenSize');          % [1 1 width_px height_px]
            figWidthNorm   = 0.25;
            figHeightNorm  = figWidthNorm * (3/4) * (screenSize(3) / screenSize(4));
            dataPlotFig = figure('Name', 'Data over time', 'NumberTitle', 'off', ...
                'Units', 'normalized', 'Position', [0.01 0.25 figWidthNorm figHeightNorm], ...
                'CloseRequestFcn', @data_plot_close_callback);
        else
            delete(dataPlotFig.Children);  % removes axes and orphaned listeners
        end

        ax1 = axes('Parent', dataPlotFig);
        hold(ax1, 'on');

        ch1FrameStart = NaN;
        ch1FrameEnd   = NaN;
        % Safety fallback: if frame numbers weren't loaded from Excel, derive from sheet size
        if isempty(xlsFrameNums)
            xlsFrameNums = 1:size(rawSheet, 2);
        end

        for ch = 1:nCh
            if size(rawSheet, 1) < ch, continue; end

            % --- Determine the analysis frame range for this channel ---
            if useVelRange && size(advancedOptions.velocityStartStop, 1) >= ch
                vS = advancedOptions.velocityStartStop(ch, 1);
                vE = advancedOptions.velocityStartStop(ch, 2);
                % velocityStartStop holds absolute frame numbers; look them up in
                % xlsFrameNums to get the corresponding column indices in rawSheet.
                % rawSheet and xlsFrameNums are now always the same length because
                % update_xlssheet reads both from the same 'B2' range.
                colS = find(xlsFrameNums >= vS, 1, 'first');
                colE = find(xlsFrameNums <= vE, 1, 'last');
                if isempty(colS) || isempty(colE) || colS > colE, continue; end
                frameSlice = xlsFrameNums(colS:colE);
                dataSlice  = rawSheet(ch, colS:colE);
                frameStart = xlsFrameNums(colS);
                frameEnd   = xlsFrameNums(colE);
            else
                % Percent Above Background: span first to last analyzed frame.
                % rawSheet columns are now guaranteed to align 1-to-1 with xlsFrameNums.
                nCols = min(size(rawSheet, 2), numel(xlsFrameNums));
                chanRow  = rawSheet(ch, 1:nCols);
                allValid = find(~isnan(chanRow));
                if isempty(allValid), continue; end
                frameSlice = xlsFrameNums(allValid(1):allValid(end));
                dataSlice  = chanRow(allValid(1):allValid(end));
                frameStart = xlsFrameNums(allValid(1));
                frameEnd   = xlsFrameNums(allValid(end));
            end

            % --- Build x positions for every frame in the slice, keeping NaN values
            % intact in yData.  MATLAB's plot() automatically breaks the line at NaN
            % positions, so unanalyzed frames within the range appear as visible gaps
            % rather than being silently bridged by a straight line segment. ---
            fNums = double(frameSlice);   % contiguous integer frame numbers

            if computeDiff
                % diff() propagates NaN naturally: if either flanking frame is NaN
                % the velocity at that interval is also NaN (rendered as a gap).
                yData = diff(dataSlice) / obj.timePerFrame;
                xSec  = ((fNums(1:end-1) + fNums(2:end)) / 2 - frameStart) ...
                        * obj.timePerFrame;
            else
                yData = dataSlice;
                xSec  = (fNums - frameStart) * obj.timePerFrame;
            end

            % Skip channels that are entirely empty within the requested range
            if numel(yData) == 0 || all(isnan(yData)), continue; end

            % Record channel-1 limits for the top frame-number axis (ax2)
            if ch == 1
                ch1FrameStart = frameStart;
                ch1FrameEnd   = frameEnd;
            end

            if ch <= numel(xlsChannelNames) && ~isempty(xlsChannelNames{ch})
                chName = xlsChannelNames{ch};
            elseif ch <= length(obj.channelNames)
                chName = obj.channelNames{ch};
            else
                chName = sprintf('Channel %d', ch);
            end

            plot(ax1, xSec, yData, ...
                'Color', obj.channelColors{ch}, ...
                'DisplayName', chName, ...
                'LineWidth', 1.5);
        end

        hold(ax1, 'off');
        xlabel(ax1, xLabelStr, 'FontWeight', 'bold');
        ylabel(ax1, yLabelStr, 'FontWeight', 'bold');
        lgd = legend(ax1, 'Location', obj.legendLocation);
        lgd.Box = 'off';
        box(ax1, 'off');
        % Explicitly span the full defined analysis range so all frames are visible
        % even when leading or trailing frames in the range have no data.
        if ~isnan(ch1FrameStart) && ~isnan(ch1FrameEnd) && ch1FrameEnd > ch1FrameStart
            ax1.XLim = [0, (ch1FrameEnd - ch1FrameStart) * obj.timePerFrame];
        end

        % Top x-axis: frame numbers corresponding to channel 1's data range
        if showFrameAxisCheckbox.Value && ~isnan(ch1FrameStart) && ~isnan(ch1FrameEnd) && ch1FrameEnd > ch1FrameStart
            % Render ax1 first so Position is accurate, then shrink from top
            % to leave room for the secondary x-axis label
            drawnow;
            axPos = ax1.Position;
            axPos(4) = axPos(4) - 0.07;   % reduce height to free top margin
            ax1.Position = axPos;
            % Map ax1's actual rendered XLim (seconds) to frame numbers
            ax2XLimStart = ch1FrameStart + ax1.XLim(1) / obj.timePerFrame;
            ax2XLimEnd   = ch1FrameStart + ax1.XLim(2) / obj.timePerFrame;
            ax2 = axes('Parent', dataPlotFig, ...
                'Units', 'normalized', ...
                'Position', axPos, ...
                'XAxisLocation', 'top', ...
                'YAxisLocation', 'right', ...
                'Color', 'none', ...
                'YTick', [], ...
                'YColor', 'none', ...
                'HitTest', 'off', ...
                'PickableParts', 'none');
            ax2.XLim = [ax2XLimStart, ax2XLimEnd];
            xlabel(ax2, 'Frame', 'FontWeight', 'bold');
            % Explicitly restrict zoom/pan to ax1 only (toolbar tools use
            % their own hit-testing, HitTest alone is not enough)
            hZoom = zoom(dataPlotFig);
            setAllowAxesZoom(hZoom, ax2, false);
            setAllowAxesZoom(hZoom, ax1, true);
            hPan = pan(dataPlotFig);
            setAllowAxesPan(hPan, ax2, false);
            setAllowAxesPan(hPan, ax1, true);
            % Return focus to ax1 so it is the target for toolbar interactions
            axes(ax1);
            % Keep ax2 (frames) in sync with ax1 (seconds) during zoom/pan
            tpf = obj.timePerFrame;
            addlistener(ax1, 'XLim', 'PostSet', @(~,~) set(ax2, ...
                'XLim', ch1FrameStart + ax1.XLim ./ tpf));
        end
    end

    function refresh_data_plot()
        if isempty(dataPlotFig) || ~isvalid(dataPlotFig), return; end
        if dataOverTimeDropdown.Value == 1, return; end
        show_data_over_time_plot();
    end

    function data_plot_close_callback(~, ~)
        % Called when the user closes the 'Data over time' figure window.
        % Reset the dropdown to "None" and disable the related controls,
        % then delete the figure.
        delete(dataPlotFig);
        dataPlotFig = [];
        set(dataOverTimeDropdown,  'Value',   1);
        set(saveDataPlotButton,    'Enable', 'off');
        set(showFrameAxisCheckbox, 'Enable', 'off');
    end

    function results_window_close_callback(~, ~)
        % Called when the user closes the main 'Sphinctalyzer: Results' window.
        % Close any open data plot first, then delete the main GUI.
        if ~isempty(dataPlotFig) && isvalid(dataPlotFig)
            delete(dataPlotFig);
            dataPlotFig = [];
        end
        delete(guiCtrl);
    end

    function save_data_plot_callback(~, ~)
        if isempty(dataPlotFig) || ~isvalid(dataPlotFig)
            warndlg('No data plot is currently open.'); return;
        end
        measureNames = {'Peak_Locations', 'Instantaneous_Velocity', 'Halfwidths', 'AUCs', 'Percent_Above_Background', 'Ring_Area'};
        measureName  = measureNames{dataOverTimeDropdown.Value - 1};
        obj = objarray(currentObj);
        [ParentFolderPath] = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        % Strip .xlsx and append measure name, save as TIFF
        baseName = currentExcelSavename(1:end-5);
        savePath = fullfile(ParentFolderPath, 'sphincRedo', [baseName, '_', measureName, '.tif']);
        try
            exportgraphics(dataPlotFig, savePath, 'Resolution', 300);
            fprintf('Data plot saved to: %s\n', savePath);
        catch ex
            errordlg(sprintf('Failed to save plot:\n%s', ex.message), 'Save Error');
        end
    end

end