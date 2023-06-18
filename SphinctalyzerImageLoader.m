function [SphinctalyzerOutputs,SaveFileName]=SphinctalyzerImageLoader(InputCells, Range, LoadMulti, ChName, ChPath, guiInput)

%% This function uses the sphinctalyzer input cell array to load images from tiff files and initialize the sphinctalyzer output array
%11/17/2014 Matthew Larson
%% Load raw images from files
if LoadMulti == 0
    %Find first channel file through GUI
    if guiInput == 0
        [ChName,ChPath] = uigetfile({'*.tif';'*.tiff'},['Select ',InputCells{1,1},' Tiff Stack']);
    end
    %Load first channel and assign relevant data to Sphinctalyzer structure
    ChannelOutputs = tiffread2(strcat(ChPath,ChName));
    SphinctalyzerOutputs=struct((matlab.lang.makeValidName([InputCells{1,1}, 'Filename'])), {ChannelOutputs.filename}, (matlab.lang.makeValidName([InputCells{1,1}, 'Data'])), {ChannelOutputs.data});
    % Make sure that Range is appropriate
    if min(Range) < 1 || max(Range) > size(SphinctalyzerOutputs,2)
        error('Range must be within size of loaded stack')
        return
    end
    % Repeat over all input channels
    for i = 2:size(InputCells, 1)
        if guiInput == 0
            [ChName,ChPath] = uigetfile({'*.tif';'*.tiff'},['Select ',InputCells{i,1},' Tiff Stack'],ChPath);
        end
        %Load channel and assign relevant data to Sphinctalyzer structure
        ChannelOutputs = tiffread2([ChPath,ChName]);
        if size(ChannelOutputs, 2) ~= size(SphinctalyzerOutputs, 2) |...
                size(ChannelOutputs(1).data) ~= size(SphinctalyzerOutputs(1).(matlab.lang.makeValidName([InputCells{1,1}, 'Data'])))
            error('All channels must be the same size and number of slices');
        end
        for j=1:size(SphinctalyzerOutputs,2)
            SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Filename'])) = ChannelOutputs(j).filename;
            SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])) = ChannelOutputs(j).data;
        end
    end
else
    %Find multichannel Tiff file through GUI-note that tiff stacks must be
    %saved in TC
    if guiInput == 0
        [ChName,ChPath] = uigetfile({'*.tif';'*.tiff'},'Select Multi-channel Tiff Stack');
    end
    %Load data
    ChannelOutputs = tiffread2([ChPath, ChName]);
    
    %Check that ChannelOutputs the number of loaded frames is divisible by
    %the number of channels, and adjust if necessary.
    CropChannel=mod(size(ChannelOutputs,2), size(InputCells,1));
    if CropChannel > 0
        display(['The last', num2str(CropChannel) 'frames have been removed']);
        ChannelOutputs=ChannelOutputs(1:end-CropChannel);
    end
    
    %Loop through images and assign them to Sphinctalyzer output data
    for i = 1:size(InputCells,1)
        for j=i:size(InputCells,1):size(ChannelOutputs,2)
            SphinctalyzerOutputs((j-i)/size(InputCells,1)+1).(matlab.lang.makeValidName([InputCells{i,1},'Filename'])) = ChannelOutputs(j).filename;
            SphinctalyzerOutputs((j-i)/size(InputCells,1)+1).(matlab.lang.makeValidName([InputCells{i,1},'Data'])) = ChannelOutputs(j).data;
        end
    end    % Make sure that Range is appropriate
    if min(Range) < 1 || max(Range) > size(SphinctalyzerOutputs,2)
        error('Range must be within size of loaded stack')
        return
    end
end
%Add field that denoting which frames are in Range and which channel is
%reference
if max(cell2mat(InputCells(:,3)))==0
    RefChannel={'Self'};
else
    RefChannel = InputCells(find(cell2mat(InputCells(:,3))==1),1);
end
for i = 1:size(SphinctalyzerOutputs,2)
    SphinctalyzerOutputs(i).RefChannel = RefChannel;
    if ismember(i,Range)
        SphinctalyzerOutputs(i).InRange=1;
    else
        SphinctalyzerOutputs(i).InRange=0;
    end
end

if guiInput == 0
    [SaveName, SavePath]=uiputfile({'*.mat'},'Where would you like to save the results?',[ChPath, 'SphinctalyzerResults.mat']);
    SaveFileName=[SavePath,SaveName];
else
    mkdir ../Sphincdata/data/sphinc/
    SaveFileName = '../Sphincdata/data/sphinc/sphinctalyzerResults.mat';
end
end
