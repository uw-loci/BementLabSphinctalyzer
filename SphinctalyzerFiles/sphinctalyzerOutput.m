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

    % display GUI
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    guiCtrl = figure('Resize','off', ...
        'Color',defaultBackground', ...
        'Units','normalized', ...
        'Position',[0.25 0.25 0.5 0.5], ...
        'Visible','on',...
        'MenuBar','none', ...
        'name', 'Sphinctalyzer: Results', ...
        'NumberTitle','off');
    
    % line scan movie options
    moviePlotOptions = uipanel('Parent',guiCtrl, ...
        'Title','Movie Plot Options', ...
        'Units','normalized', ...
        'FontSize', 12, ...
        'Position',[0 0.4 0.33 0.6]);
            
    changeXAxis = uicontrol('Parent',moviePlotOptions, ...
        'Style','pushbutton', ...
        'String','Edit X Axis', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0.1 0.9 .35 .075], ...
        'Callback',{@change_x_axis});   
    changeYAxis = uicontrol('Parent',moviePlotOptions, ...
        'Style','pushbutton', ...
        'String','Edit Y Axis', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0.55 0.9 .35 .075], ...
        'Callback',{@change_y_axis});
    darkBackgroundLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Dark Background', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 0.8 .85 .075]);
    darkBackground = uicontrol('Parent',moviePlotOptions, ...
        'Style','checkbox', ...
        'Enable','on', ...
        'String','', ...
        'Min',0,'Max',1, ...
        'Units','normalized', ...
        'Position', [.85 .815 .18 .075], ...
        'Value', 0, ...
        'Callback', {@darkBackgroundCbx});   
    normalizationLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Normalization', ...
        'FontSize',10, ...
        'Units', 'normalized', ...
        'Position',[0 0.7 .85 .075]);
    enterNormalization = uicontrol('Parent',moviePlotOptions, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[.81 0.715 .14 .075], ...
        'Callback',{@get_textbox_normalization});
    micronsPerPixelLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Microns Per Pixel', ...
        'FontSize',10, ...
        'Units', 'normalized', ...
        'Position',[0 .6 .85 .075]);
    enterMicronsPerPixel = uicontrol('Parent',moviePlotOptions, ...
        'Style','edit', ...
        'String','1', ...
        'BackgroundColor','w', ...
        'Min',0,'Max',1, ...
        'UserData',1, ...
        'Units','normalized', ...
        'Position',[.81 .615 .14 .075], ...
        'Callback',{@get_textbox_micronsPerPixel});
    timePerFrameLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Time Per Frame', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 .5 .85 .075]);
    enterTimePerFrame = uicontrol('Parent',moviePlotOptions, ...
        'Style','edit', ...
        'String',num2str(getappdata(guiCtrl,'timePerFrame')), ...
        'BackgroundColor', ...
        'w', ...
        'Min',0,'Max',1, ...
        'UserData',getappdata(guiCtrl,'timePerFrame'),'Units', ...
        'normalized', ...
        'Position',[.81 .515 .14 .075], ...
        'Callback',{@get_timePerFrame});
    legendLocationLabel = uicontrol('Parent',moviePlotOptions, ...
        'Style','text', ...
        'String','Legend Location', ...
        'FontSize',10, ...
        'Units','normalized', ...
        'Position',[0 .4 .85 .075]);
    enterLegendLocation = uicontrol('Parent',moviePlotOptions, ...
        'Style','popupmenu', ...
        'String',{'NorthWest','NorthEast','SouthWest','SouthEast'}, ...
        'units','normalized', ...
        'Value',1 ,...
        'Position',[.6 .415 .38 .075], ...
        'Callback',{@get_legend_location});  
    writeMovieButton = uicontrol('Parent',moviePlotOptions, ...
        'Style','pushbutton', ...
        'String','Write Movie', ...
        'Units', 'Normalized', ...
        'Position',[0.1 0.01 0.8 0.075], ...
        'Callback',{@write_movie});
    
    %view options panel
    viewOptionsPanel = uipanel('Parent',guiCtrl, ...
        'Title','View Options', ...
        'Units','normalized', ...
        'FontSize', 12, ...
        'Position',[0 0 0.33 0.38]);
    colorMapSelection = uicontrol('Parent',viewOptionsPanel, ...
        'Style','popupmenu', ...
        'String',{'Default Colormap' 'MATLAB Color: JET' 'MATLAB Color: Gray' 'MATLAB Color: hsv' 'MATLAB Color: Hot' 'MATLAB Color: Cool'}, ...
        'Units','normalized', ...
        'Position',[0.15 0.7 0.7 0.2], ...
        'Callback',{@change_color_map});
    viewerSelectionTable = uicontrol('Parent',viewOptionsPanel, ...
        'Style','listbox', ...
        'String',{'Image Timepoints', 'scan movietalyzerResults_1'}, ...
        'Units','normalized', ...
        'Position',[0.05 0.1 0.9 0.6], ...
        'Callback',{@viewer_selection});

    % stack previewer 
    imagePanel = uipanel('Parent',guiCtrl, ...
        'Units','normalized', ...
        'Position',[0.375 0.45 0.58 0.5]);    
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
    'RowName', {'Peak Intens', 'Peak Locs', 'Halfwidths', 'AUCs', '% Abv Backg', 'Closing Vel'},...
    'Units','normalized', ...
    'Position',[0.3525 0.12 0.35 .285]);
    
    % image queue panel
    imageQueuePanel = uipanel('Parent',guiCtrl, ...
        'Title', 'Image Queue Panel', ...
        'FontSize', 12, ...
        'Units','normalized', ...
        'Position',[0.7275 0.12 0.2475 0.285]);
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
        [ParentFolderPath] = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        rangeStart = 'C2';
        xlsSheets = cell(1,5);
        xlsSheets{1} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results.xls'),'Sheet', 'Peak Intensity','Range',rangeStart);
        xlsSheets{2} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Sheet','Peak Locations','Range',rangeStart);
        xlsSheets{3} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Sheet','Halfwidths','Range',rangeStart);
        xlsSheets{4} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Sheet','AUCs','Range',rangeStart);
        xlsSheets{5} = readmatrix(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Sheet','Percent Above Background','Range',rangeStart);
        
        for m = 1:3
            for n = 1:6
                imageSliderDataPanel.Data{n, m} = ' ';
            end
        end
        % calculate wound closing velocity
        peakLocations = xlsSheets{1};
        for b = 1:obj.nChannels
            woundClosingVelocity = ((peakLocations(b, obj.velocityStartStop(2)) - peakLocations(b, obj.velocityStartStop(1))) / ((obj.velocityStartStop(2) - obj.velocityStartStop(1)) * obj.timePerFrame)) * obj.micronsPerPixel;
            imageSliderDataPanel.Data{6, b} = woundClosingVelocity;
        end

        referenceArray = [obj.cellArray{:,3}];
        % load in SphinctalyzerOutputs data structure
        pathToResults = strcat(ParentFolderPath,'/sphincRedo/sphinctalyzerResults.mat');
        SphincOutputs = load(pathToResults);
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
        for i = 1:obj.nChannels
            channelColor = obj.channelColors{i};
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
                'String',strcat('channel',num2str(i)), ...
                'FontSize',10, ...
                'Units','normalized', ...
                'Position',[0 .4-(i*0.1) .85 .075]);
            enterChannelColor(i) = uicontrol('Parent',moviePlotOptions, ...
                'Style','popupmenu', ...
                'String',{'red';'green';'blue';'cyan';'magenta';'yellow';'black';'white'}, ...
                'Units','normalized', ...
                'Position',[0.6 .415-(i*0.1) .38 .075], ...
                'Value',colorValue, ...
                'Callback', {@cc_button, i});
        end
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
        for i=1:size(validnames,1)
            if ~any(strcmp(obj.moviePaths, fullfile(validnames(i).folder,validnames(i).name)))
                obj.moviePaths = [obj.moviePaths; fullfile(validnames(i).folder,validnames(i).name)];
                current = get(viewerSelectionTable, 'String');
                current = [current; strcat('scan movietalyzerResults_', num2str(length(obj.moviePaths)))];
                set(viewerSelectionTable,'String',current)
                objarray(currentObj) = obj;
            end
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
                length(obj.moviePaths) + 1, ...
                obj.imageName)
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
                    'pos',[0.1 1-(u*0.15) 0.8 0.12], ...
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
                    obj.imageName)

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
                update_image_data_panel(iTimepoint)
                set(labelTitle, 'String', sprintf('Current Frame = %d/%d', iTimepoint + obj.timepointStart - 1, obj.nTimepoints))
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
        % calculate wound closing velocity
        peakLocations = xlsSheets{1};
        for b = 1:obj.nChannels
            woundClosingVelocity = ((peakLocations(b, obj.velocityStartStop(2)) - peakLocations(b, obj.velocityStartStop(1))) / ((obj.velocityStartStop(2) - obj.velocityStartStop(1)) * obj.timePerFrame)) * obj.micronsPerPixel;
            imageSliderDataPanel.Data{6, b} = woundClosingVelocity;
        end
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
        % calculate wound closing velocity
        peakLocations = xlsSheets{1};
        for b = 1:obj.nChannels
            woundClosingVelocity = ((peakLocations(b, obj.velocityStartStop(2)) - peakLocations(b, obj.velocityStartStop(1))) / ((obj.velocityStartStop(2) - obj.velocityStartStop(1)) * obj.timePerFrame)) * obj.micronsPerPixel;
            imageSliderDataPanel.Data{6, b} = woundClosingVelocity;
        end
    end
    
    function get_legend_location(hObject, event)
        legend_locations = {'NorthWest','NorthEast','SouthWest','SouthEast'};
        selected_legend_location = legend_locations{get(hObject, 'Value')};
        objarray(currentObj).legendLocation = selected_legend_location;
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
        for m = 1:obj.nChannels
            for n = 1:5
                sheet = xlsSheets{n};
                imageSliderDataPanel.Data{n, m} = sheet(m, obj.timepointStart + currentTimepoint - 1);
            end
        end
    end
end