function [UserDrawnBounds]=SphinctalyzerInitializeCircleBounds(SphinctalyzerOutputs, InputCells, colorMap,guiInput,roiShape)

% Open new figure
figAnnotation = figure('Name','Annotating the Brightest Path', 'NumberTitle','off','NextPlot','replace');
% ax1 = figAnnotation.CurrentAxes;
ROIdeleted_flag = 0;

if strcmp(SphinctalyzerOutputs(1).RefChannel,'Self') %Loop if each channel is scanned separately
    i = 1:size(InputCells,1);
else %only use ref frame
    i = find(cell2mat(InputCells(:,3))==1);
end

%loop through images
for i = i
    imagesc(SphinctalyzerOutputs(InputCells{i,2}).(matlab.lang.makeValidName([InputCells{i,1},'Data']))); %display image
    colormap (colorMap)
    axis image
    title('Trace the brightest path, then double click inside the ROI')
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

