function [UserDrawnBounds]=SphinctalyzerInitializeCircleBounds(SphinctalyzerOutputs, InputCells, colorMap,guiInput,roiShape)
% Open new figure
figure

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
    if guiInput == 1
        funcs = {@drawcircle,@drawellipse,@drawfreehand,@drawassisted,@drawpolygon,@drawrectangle};
        title('Trace the brightest path')
        h=funcs{roiShape}();
    else
        title(['Trace the brightest path, then double click'])%, InputCells{i,1}])
        position=[];
        while isempty(position)
            h=imfreehand; %define inner mask
            position=wait(h);
        end
    end
    UserDrawnBounds(i).BWMaskOut=createMask(h);
end

%close figure
close gcf

end

