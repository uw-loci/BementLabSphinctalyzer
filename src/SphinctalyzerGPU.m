function SphinctalyzerGPU

%% Input parameter initialization
% Set up input vaiables in cell array
InputCells={
    % Channel Name    DisplayFrame   Isreference? Use \Delta for ?, other symbols found at https://www.clemson.edu/ces/crb/procedures/greek/mat_greek.htm
    'Gfp-wGBD',            13,             1
    'che-UtrCH',           12,             0
    };
% One variable per line, as many lines as you want
% Change ONLY ONE IsReference to 1 to use that as the reference channel
Range = 5:15;  % Select the range of images to scan in form first frame:last frame
inspeed = 3;  % Select maximum inward speed of ring
outspeed = 3;  % Select maximum outward speed of ring
LoadMulti = 0; % 0 for loading each channel individually, 1 for loading a multi-channel tiff
ScanShape = 1; % 1 for closed loop (circle) scan
DetectionMethod = 2; % Zero for basic brightest-point dilation,
% 2 for two Livewire iterations, 3 for three Livewire iterations, 1 is for
% idiots
Step=20; %Line segment length for livewire operation

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
[SphinctalyzerOutputs, SaveFileName]=SphinctalyzerImageLoader(InputCells, Range, LoadMulti);

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
            waitincrement=length(RefCheckMatrix).*(length(Range)+1);
            waitposition=0;
            h = waitbar(0,'Sphinctalyzing','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
            setappdata(h,'canceling',0);
            for i=1:size(RefCheckMatrix,1)
                RefFrame=DisplayFrameMatrix(i);
                [SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'cpX'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'cpY']))] = CircleScanLivewireGPU(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                    SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), UserDrawnBounds(i).BWMaskOut, 1, DetectionMethod, Step);
                waitposition=waitposition+1;
                waitbar(waitposition/waitincrement)
                if getappdata(h,'canceling')
                    save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                    delete(h);
                    break
                end
                for j=RefFrame+1:max(Range)
                    [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])),SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'cpX'])),SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'cpY']))] = CircleScanLivewireGPU(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                        SphinctalyzerOutputs(j-1).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), SphinctalyzerOutputs(j-1).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), 0, DetectionMethod, Step,SphinctalyzerOutputs(j-1).(matlab.lang.makeValidName([InputCells{i,1},'cpX'])),SphinctalyzerOutputs(j-1).(matlab.lang.makeValidName([InputCells{i,1},'cpY'])));
                    [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'XDistances'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'MeanIntensities'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'IntensityStDev'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'PointsPerGroup'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'MedianIntensities'])),SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])));
                    waitposition=waitposition+1;
                    waitbar(waitposition/waitincrement)
                    if getappdata(h,'canceling')
                        save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                        delete(h);
                        break
                    end
                end
                for j=RefFrame:-1:min(Range)
                    [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])),SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'cpX'])),SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'cpY']))] = CircleScanLivewireGPU(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                        SphinctalyzerOutputs(j+1).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), SphinctalyzerOutputs(j+1).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), 0, DetectionMethod, Step,SphinctalyzerOutputs(j+1).(matlab.lang.makeValidName([InputCells{i,1},'cpX'])),SphinctalyzerOutputs(j+1).(matlab.lang.makeValidName([InputCells{i,1},'cpY'])));
                    [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'XDistances'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'MeanIntensities'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'IntensityStDev'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'PointsPerGroup'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'MedianIntensities'])),SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])));
                    waitposition=waitposition+1;
                    waitbar(waitposition/waitincrement)
                    if getappdata(h,'canceling')
                        save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                        delete(h);
                        break
                    end
                end
            end
        else
            RefChannel=find(RefCheckMatrix==max(RefCheckMatrix));
            RefFrame=DisplayFrameMatrix(RefChannel);
            RefName=InputCells{logical(RefCheckMatrix),1};
            NonRefName=InputCells(~logical(RefCheckMatrix),1);waitincrement=length(RefCheckMatrix).*length(Range);
            waitincrement=length(Range)+1;
            waitposition=0;
            h = waitbar(0,'Sphinctalyzing','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
            setappdata(h,'canceling',0);
           [SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Outline'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'cpX'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'cpY']))] = CircleScanLivewireGPU(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])),...
                SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])), UserDrawnBounds(RefChannel).BWMaskOut, 1, DetectionMethod, Step);

            waitposition=waitposition+1;
            waitbar(waitposition / waitincrement)
            if getappdata(h,'canceling')
                save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                delete(h);
                return
            end
            for k=RefFrame+1:max(Range)
                [SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'cpX'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'cpY']))] = CircleScanLivewireGPU(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Data'])),...
                    SphinctalyzerOutputs(k-1).(matlab.lang.makeValidName([RefName,'Data'])), SphinctalyzerOutputs(k-1).(matlab.lang.makeValidName([RefName,'Outline'])), 0, DetectionMethod, Step,SphinctalyzerOutputs(k-1).(matlab.lang.makeValidName([RefName,'cpX'])),SphinctalyzerOutputs(k-1).(matlab.lang.makeValidName([RefName,'cpY'])));
                [SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'XDistances'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'MeanIntensities'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'IntensityStDev'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'PointsPerGroup'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'MedianIntensities'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Data'])));
                if ~isempty(NonRefName)
                    for j = 1:size(NonRefName,1)
                        [SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'XDistances'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'MeanIntensities'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'IntensityStDev'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'PointsPerGroup'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'MedianIntensities'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'Data'])));
                    end
                end
                waitposition=waitposition+1;
                waitbar(waitposition / waitincrement)
                if getappdata(h,'canceling')
                    save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                    delete(h);
                    break
                end
            end
            for k=RefFrame:-1:min(Range)
                [SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'cpX'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'cpY']))] = CircleScanLivewireGPU(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Data'])),...
                    SphinctalyzerOutputs(k+1).(matlab.lang.makeValidName([RefName,'Data'])), SphinctalyzerOutputs(k+1).(matlab.lang.makeValidName([RefName,'Outline'])), 0, DetectionMethod, Step,SphinctalyzerOutputs(k+1).(matlab.lang.makeValidName([RefName,'cpX'])),SphinctalyzerOutputs(k+1).(matlab.lang.makeValidName([RefName,'cpY'])));
                [SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'XDistances'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'MeanIntensities'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'IntensityStDev'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'PointsPerGroup'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'MedianIntensities'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Data'])));
                if ~isempty(NonRefName)
                    for j = 1:size(NonRefName,1)
                        [SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'XDistances'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'MeanIntensities'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'IntensityStDev'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'PointsPerGroup'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'MedianIntensities'])),SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])), SphinctalyzerOutputs(k).(matlab.lang.makeValidName([NonRefName{j,1},'Data'])));
                    end
                end
                waitposition=waitposition+1;
                waitbar(waitposition / waitincrement)
                if getappdata(h,'canceling')
                    save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                    delete(h);
                    break
                end
            end
        end
        delete(h);
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
