function [UserDrawnBounds]=SphinctalyzerInitializeCircleBounds(SphinctalyzerOutputs, InputCells, colorMap,guiInput,roiShape)

%% SPHINCTALYZERINITIALIZECIRCLEBOUNDS 
%   Handles the initialization of circle bounds for image annotation.
%   [USERDRAWNBOUNDS] = SPHINCTALYZERINITIALIZECIRCLEBOUNDS(SPHINCTALYZEROUTPUTS, INPUTCELLS, COLORMAP, GUIINPUT, ROISHAPE)
%   Displays an image for the user to manually draw paths (ROIs), and optionally reuses previously saved paths.
%
%   INPUTS:
%       SphinctalyzerOutputs - Image data outputs used for display.
%       InputCells           - Cell array containing channel info, display frame, and reference flag.
%       colorMap             - Colormap used for image visualization.
%       guiInput             - Determines GUI behavior for path drawing.
%       roiShape             - Shape of the ROI drawn by the user (e.g., circle, rectangle).
%
%   OUTPUTS:
%       UserDrawnBounds - Contains the manually drawn or reused paths.
%
%   Key operations:
%   - Extracts the reference channel and frame position from InputCells.
%   - Checks for a previously saved path via the `validateSavedPath` function.
%   - If no valid path exists, prompts the user to draw a new one and saves it.
%
%%

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
fieldsname = fieldnames(SphinctalyzerOutputs);
[imgPath, imgName, imgExt] = fileparts(SphinctalyzerOutputs(1).(fieldsname{1}));
refChannelIdx = find(cell2mat(InputCells(:, 3)) == 1);
if isempty(refChannelIdx)
    error('No reference channel selected in InputCells.');
end
refChannelName = InputCells{refChannelIdx, 1};
framePosition = InputCells{refChannelIdx, 2};

[reuseSavedPath, UserDrawnBounds, saveFileName] = validateSavedPath(imgPath, imgName, refChannelName, framePosition, colorMap, figAnnotation);

if reuseSavedPath
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

