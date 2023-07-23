function moviePlayer(moviePath, timepointStart, nTimepoints)
    % input parameters: movie path, starting timepoint, number timepoints
    global iTimepoint
    iTimepoint = 1;
    
    mov = VideoReader(moviePath);
    moviePlayer = figure('Units','normalized','Position',[0.2 0.2 0.4 0.35],'Visible','on',...
            'MenuBar','none','name','Movie Player','NumberTitle','off','UserData',0);
    frameRate = {num2str(mov.FrameRate)};
    imgAx = axes('Parent',moviePlayer,'YTick',[],'XTick',[],'Units','normalized',...
        'Position',[0 0.05 1 0.9]);
    
    sliderMin = 1;
    sliderMax = mov.NumFrames;
    timepointSlider = uicontrol('Parent',moviePlayer, ...
        'Style','slide', ...
        'Units','normalized', ...
        'position',[0 0 1 0.05], ...
        'min',sliderMin,'max',sliderMax,...
        'val',1, ...
        'SliderStep', [1 1]/(sliderMax-sliderMin),'Enable','on');
    addlistener(timepointSlider,'ContinuousValueChange', ...
        @(hObject, event) updateImageTimepoint(hObject, event, mov));

    movieFrameRate = uicontrol('Parent',moviePlayer,...
        'Style','pushbutton','String','Change Frame Rate', ...
        'Units','normalized', ...
        'Position',[0.8 0.94 0.2 0.05],...
        'Callback',{@change_frame_rate});

    playButton = uicontrol('Parent',moviePlayer,...
        'Style','pushbutton','String','Play', ...
        'Units','normalized', ...
        'Position',[0 0.94 0.1 0.05],...
        'Callback',{@play});
    
    frame = read(mov, 1);
    imagesc(frame,'Parent',imgAx);
    set(imgAx,'YTick',[],'XTick',[]);
    axis image equal
    drawnow 
    title(sprintf('Current Frame = %d/%d', timepointStart, nTimepoints));
    
    function updateImageTimepoint(hObject, event, mov)
        iTimepoint = round(hObject.Value);
        frame = read(mov, iTimepoint);
        imagesc(frame,'Parent',imgAx);
        set(imgAx,'YTick',[],'XTick',[]);
        axis image equal
        drawnow
        title(sprintf('Current Frame = %d/%d', iTimepoint + timepointStart - 1, nTimepoints));
    end

    function change_frame_rate(hObject,eventdata)
        prompt = 'Enter frame rate:';
        definput = {num2str(frameRate{1})};
        dims = [1 35];
        dlgtitle = 'Change Frame Rate';
        answer = inputdlg(prompt,dlgtitle,dims, definput);
        if ~isempty(answer)
            if ~isnan(str2double(answer))
                frameRate = answer;
            end
        end
    end
    
    function play(hObject,eventdata)
        pauseS = false;
        pauseButton = uicontrol('Parent',moviePlayer,...
            'Style','pushbutton','String','Pause', ...
            'Units','normalized', ...
            'Position',[0.12 0.94 0.1 0.05],...
            'Callback',{@pause_callback});
        while iTimepoint < sliderMax
            currentFrame = iTimepoint;
            if pauseS == false
                pause(1/str2double(frameRate{1}))
                currentFrame = currentFrame + 1;
                set(timepointSlider,'Value',currentFrame)
                frame = read(mov, currentFrame);
                imagesc(frame,'Parent',imgAx);
                set(imgAx,'YTick',[],'XTick',[]);
                axis image equal
                drawnow
                title(sprintf('Current Frame = %d/%d', iTimepoint + timepointStart, nTimepoints));
                iTimepoint = currentFrame;
            else
                break
            end
        end
        delete(pauseButton)

        function pause_callback(hObject,eventdata)
            pauseS = true;
            delete(hObject)
        end
    end
end