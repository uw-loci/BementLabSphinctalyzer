function [SaveFileName]=SphinctalyzerInitializer(cellInputParam, startSlice, stopSlice, speed, multiCheck, shapeParam, detectionParam, smoothParam, stepParam, filePath, fileName)

%% Input parameter initialization
% Set up input vaiables in cell array
guiInput = 1;
if guiInput == 0
    filePath = '';
    fileName = '';
    InputCells={
        % Channel Name    DisplayFrame   Isreference? Use \Delta for ?, other symbols found at https://www.clemson.edu/ces/crb/procedures/greek/mat_greek.htm
        'dTomato-rGBD',            36,             1
        'GFP-wGBD',                     22,             0};
    % One variable per line, as many lines as you want
    % Change ONLY ONE IsReference to 1 to use that as the reference channel
    Range = 9:40;  % Select the range of images to scan in form first frame:last frame
    inspeed = 3;  % Select maximum inward speed of ring
    outspeed = 3;  % Select maximum outward speed of ring
    LoadMulti = 1; % 0 for loading each channel individually, 1 for loading a multi-channel tiff
    ScanShape = 1; % 1 for closed loop (circle) scan
    DetectionMethod = 3; % Zero for basic brightest-point dilation,
    SmoothNo=0;
    % 2 for two Livewire iterations, 3 for three Livewire iterations, 1 is for
    % idiots
    Step=8; %Line segment length for livewire operation
else
    InputCells = cellInputParam;
    Range = startSlice:stopSlice;
    inspeed = speed;
    outspeed = speed;
    LoadMulti = multiCheck;
    ScanShape = shapeParam;
    DetectionMethod = detectionParam;
    SmoothNo = smoothParam;
    Step = stepParam;
end

%% Parse inputs for errors
% Make sure that no more than one reference frame is chosen
RefCheckMatrix=cell2mat(InputCells(:,3)); %Retirieve reference indices
if min(ismember(RefCheckMatrix,[0 1])) == 0 || sum(RefCheckMatrix) > 1
    error('Reference category may contain all zeros or all zeros with one 1 denoting referece frame')
end
%Make sure that display frames are within range
DisplayFrameMatrix=cell2mat(InputCells(:,2));
if min(ismember(DisplayFrameMatrix,Range)) == 0
    error('All Display Frames must be contained within Range')
end
% Check that LoadMulti is valid
if ~ismember(LoadMulti,[0 1])
    error('LoadMulti must be zero or one')
end
% Check that DetectionMethod is valid
if ~ismember(DetectionMethod, [0 1 2 3])
    error('DetectionMethod must be 0 1 or 2')
end

%% Load images and initialize output matrix
[SphinctalyzerOutputs, SaveFileName]=SphinctalyzerImageLoader(InputCells, Range, LoadMulti, fileName, filePath, guiInput);

%% Select initial regions
if ScanShape == 1
    [UserDrawnBounds]=SphinctalyzerInitializeCircleBounds(SphinctalyzerOutputs, InputCells);
else
    error('ScanShape must be 1, because I only do circles for now.....')
end

tic
try
    %% Perform Scan
    if ScanShape == 1
        if max(RefCheckMatrix)==0
            for i=1:size(RefCheckMatrix,1)
                RefFrame=DisplayFrameMatrix(i);
                SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                    SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), UserDrawnBounds(i).BWMaskOut, 1, DetectionMethod, Step,SmoothNo);
            end
        else
            RefChannel=find(RefCheckMatrix==max(RefCheckMatrix));
            RefFrame=DisplayFrameMatrix(RefChannel);
            RefName=InputCells{logical(RefCheckMatrix),1};
            NonRefName=InputCells(~logical(RefCheckMatrix),1);waitincrement=length(RefCheckMatrix).*length(Range);
            SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])),...
                SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])), UserDrawnBounds(RefChannel).BWMaskOut, 1, DetectionMethod, Step,SmoothNo);
        end
    else
        error('ScanShape must be 1, because I only do circles for now.....')
    end
    
    %% Save the results
    save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds')
    
catch err
    
    save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
    delete(h);
    rethrow(err)
end
toc
