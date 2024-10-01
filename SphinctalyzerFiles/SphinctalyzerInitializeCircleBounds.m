function [UserDrawnBounds]=SphinctalyzerInitializeCircleBounds(SphinctalyzerOutputs, InputCells, colorMap,guiInput,roiShape)

% Open new figure
ssU = get(0,'ScreenSize');
WidthvsDepth = ssU(3)/ssU(4);
figWidth = 0.475;
figDepth = 0.475*WidthvsDepth;
if figDepth > 1
    figDepth = 0.8;
end
figAnnotation = figure('Units','normalized', ...
        'Position',[0.415 0.10 figWidth figDepth],'NumberTitle','off','NextPlot','replace');
% ax1 = figAnnotation.CurrentAxes;
%get the file name of the frame
if isfield(SphinctalyzerOutputs(1), 'channel1Filename')
    if ~isempty(SphinctalyzerOutputs(1).channel1Filename)
        [~, imgName, imgExt] = fileparts(SphinctalyzerOutputs(1).channel1Filename);
    else
        imgName = 'channel1';
        imgExt = '';
    end
else
    imgName = 'channel1';
    imgExt = '';
end

% Extract `refChannelName` and `framePosition` from InputCells
refChannelIdx = find(cell2mat(InputCells(:, 3)) == 1);  % Get reference channel index
if isempty(refChannelIdx)
    error('No reference channel selected in InputCells.');
end
refChannelName = InputCells{refChannelIdx, 1};  % Get reference channel name
framePosition = InputCells{refChannelIdx, 2};  % Assuming "Display Frame" is in the second column

% Call the new function to validate and potentially reuse the saved path
[reuseSavedPath, UserDrawnBounds, saveFileName] = validateSavedPath(imgName, refChannelName, framePosition, colorMap, figAnnotation);

if reuseSavedPath
    % Close the figure if the user selects to reuse the saved path
    close(figAnnotation);
    return;
end

ROIdeleted_flag = 0;

if strcmp(SphinctalyzerOutputs(1).RefChannel,'Self') %Loop if each channel is scanned separately
    i = 1:size(InputCells,1);
else %only use ref frame
    i = find(cell2mat(InputCells(:,3))==1);
end

%loop through images
for i = i
    figure(figAnnotation);
    imagesc(SphinctalyzerOutputs(InputCells{i,2}).(matlab.lang.makeValidName([InputCells{i,1},'Data']))); %display image
    colormap (colorMap)
    axis image
    title('Trace the brightest path, then double click inside the ROI')
    figAnnotation.Name = sprintf('Annotating the reference frame of %s',strcat(imgName,imgExt));
    figAnnotation.NumberTitle = 'off';
    drawROI(figAnnotation,guiInput)
end
%
    function drawROI(figAnnotation,guiInput)
        figure(figAnnotation)
        if ROIdeleted_flag == 1
            imagesc(SphinctalyzerOutputs(InputCells{i,2}).(matlab.lang.makeValidName([InputCells{i,1},'Data']))); %display image
            colormap (colorMap)
            axis image
            title('Trace the brightest path, then double click inside the ROI')            
        end
        if guiInput == 1
            funcs = {@drawcircle,@drawellipse,@drawfreehand,@drawassisted,@drawpolygon,@drawrectangle};
            position=[];
            h=funcs{roiShape}();
            ROIdeleted_flag = 0; 
            % Listen for mouse clicks on the ROI
            l = addlistener(h,'ROIClicked',@clickCallback);
            % Listen for ROI deleting
            l1 = addlistener(h,"DeletingROI",@allevents);
            position = customWait(h,l,l1);
        else
            position=[];
            while isempty(position)
                h=imfreehand; %define inner mask
                position=wait(h);
            end
        end
        if ROIdeleted_flag == 0
            UserDrawnBounds(i).BWMaskOut=createMask(h);
            UserDrawnBounds(i).Position = h.Position;

            % Save the drawn path into the fixed directory (baseOutputPath)
            save(saveFileName, 'UserDrawnBounds', 'imgName', 'refChannelName', 'framePosition');  % Save with validation parameters
            disp(['New path saved as ', saveFileName]);
            delete(h);

            %close figure
            close(figAnnotation);
        else
            % UserDrawnBounds = [];
            drawROI(figAnnotation,guiInput);
        end
    end
%
    function pos = customWait(hROI,l,l1)

       % Block program execution
        uiwait;
        % Remove listener
        delete(l);
        delete(l1)
        if ROIdeleted_flag == 0
            % Return the current position
            pos = hROI.Position;
        else
            pos = [];
        end
        
    end

    function clickCallback(~,evt)
        if strcmp(evt.SelectionType,'double')
            uiresume;
        end
    end

    function allevents(src,evt)
        fprintf('Previous annotation is unavailable, re-draw a new one \n')
        uiresume
        ROIdeleted_flag = 1;
        % SphinctalyzerInitializeCircleBounds(SphinctalyzerOutputs, InputCells, colorMap,guiInput,roiShape)
    end

end

