function [SphinctalyzerOutputs,SaveFileName,UserDrawnBounds]=SphinctalyzerImageLoader(InputCells, Range, LoaderInputs,SavePath,SaveName)

%% This function uses the sphinctalyzer input cell array to load images from tiff files and initialize the sphinctalyzer output array
%11/17/2014 Matthew Larson


%Loop through images and assign them to Sphinctalyzer output data
for i = 1:size(InputCells,1)

        [SphinctalyzerOutputs(1:numel(LoaderInputs)).(matlab.lang.makeValidName([InputCells{i,1},'Filename']))]=LoaderInputs.(matlab.lang.makeValidName([InputCells{i,1},'Filename']));
        [SphinctalyzerOutputs(1:numel(LoaderInputs)).(matlab.lang.makeValidName([InputCells{i,1},'Data']))]=LoaderInputs.(matlab.lang.makeValidName([InputCells{i,1},'Data']));

end    % Make sure that Range is appropriate
if min(Range) < 1 || max(Range) > size(SphinctalyzerOutputs,2)
    error('Range must be within size of loaded stack')
    return
end
%Add field that denoting which frames are in Range and which channel is
%reference
if max(cell2mat(InputCells(:,3)))==0
    RefChannel={'Self'};
    for j=1:size(InputCells,1)
        UserDrawnBounds(j).BWMaskOut=LoaderInputs(InputCells{j,2}).(matlab.lang.makeValidName([InputCells{j,1},'Outline']));
    end
else
    RefChannel = InputCells(find(cell2mat(InputCells(:,3))==1),1);
    UserDrawnBounds(find(cell2mat(InputCells(:,3))==1)).BWMaskOut=LoaderInputs(InputCells{find(cell2mat(InputCells(:,3))==1),2}).(matlab.lang.makeValidName([InputCells{find(cell2mat(InputCells(:,3))==1),1},'Outline']));
end
for i = 1:size(SphinctalyzerOutputs,2)
    SphinctalyzerOutputs(i).RefChannel = RefChannel;
    if ismember(i,Range)
        SphinctalyzerOutputs(i).InRange=1;
    else
        SphinctalyzerOutputs(i).InRange=0;
    end
end


mkdir([SavePath,'Redo'])
SaveFileName=[SavePath,'Redo/',SaveName];
end

