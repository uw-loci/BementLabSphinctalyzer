function SphinctalyzerInitialized(filename,path)

%% Input parameter initialization
% Set up input vaiables in cell array
load([path,'/',filename]);
Range = find([SphinctalyzerOutputs(:).InRange]==1);  % Select the range of images to scan in form first frame:last frame
inspeed = 3;  % Select maximum inward speed of ring
outspeed = 3;  % Select maximum outward speed of ring
LoadMulti = 1; % 0 for loading each channel individually, 1 for loading a multi-channel tiff
ScanShape = 1; % 1 for closed loop (circle) scan
DetectionMethod = 3; % Zero for basic brightest-point dilation,% 2 for two Livewire iterations, 3 for three Livewire iterations, 1 is for
% idiots
SmoothNo=0;

Step=8; %Line segment length for livewire operation



%% Load images and initialize output matrix
[SphinctalyzerOutputs, SaveFileName,UserDrawnBounds]=SphinctalyzerImageLoaderRescue(InputCells, Range,SphinctalyzerOutputs,path,filename);

%% Select initial regions
RefCheckMatrix=cell2mat(InputCells(:,3)); %Retirieve reference indices
DisplayFrameMatrix=cell2mat(InputCells(:,2));
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
                SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                    SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), UserDrawnBounds(i).BWMaskOut, 1, DetectionMethod, Step,SmoothNo);
                [SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'XDistances'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'MeanIntensities'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'IntensityStDev'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'PointsPerGroup'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'MedianIntensities'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([InputCells{i,1},'Data'])));
                waitposition=waitposition+1;
                waitbar(waitposition/waitincrement)
                if getappdata(h,'canceling')
                    save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                    delete(h);
                    break
                end
                for j=RefFrame+1:max(Range)
                    %ApproxCentroid=round(stats.Centroid);
                    SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                        SphinctalyzerOutputs(j-1).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), SphinctalyzerOutputs(j-1).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), 0, DetectionMethod, Step,SmoothNo);
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
                    SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([InputCells{i,1},'Data'])),...
                        SphinctalyzerOutputs(j+1).(matlab.lang.makeValidName([InputCells{i,1},'Data'])), SphinctalyzerOutputs(j+1).(matlab.lang.makeValidName([InputCells{i,1},'Outline'])), 0, DetectionMethod, Step,SmoothNo);
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
            waitincrement=length(Range);
            waitposition=0;
            h = waitbar(0,'Sphinctalyzing','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
            setappdata(h,'canceling',0);
            SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])),...
                SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])), UserDrawnBounds(RefChannel).BWMaskOut, 1, DetectionMethod, Step,SmoothNo);
            [SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'XDistances'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'MeanIntensities'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'IntensityStDev'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'PointsPerGroup'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'MedianIntensities'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Outline'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Data'])));
            if ~isempty(NonRefName)
                for j = 1:size(NonRefName,1)
                    [SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'XDistances'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'MeanIntensities'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'IntensityStDev'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'PointsPerGroup'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'MedianIntensities'])),SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'SmoothIntensities']))]=CircleScanOutlineAvg(SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([RefName,'Outline'])), SphinctalyzerOutputs(RefFrame).(matlab.lang.makeValidName([NonRefName{j,1},'Data'])));
                end
            end
            waitposition=waitposition+1;
            waitbar(waitposition / waitincrement)
            if getappdata(h,'canceling')
                save(SaveFileName, 'SphinctalyzerOutputs','InputCells','UserDrawnBounds');
                delete(h);
                return
            end
            for k=RefFrame+1:max(Range)
                SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Data'])),...
                    SphinctalyzerOutputs(k-1).(matlab.lang.makeValidName([RefName,'Data'])), SphinctalyzerOutputs(k-1).(matlab.lang.makeValidName([RefName,'Outline'])), 0, DetectionMethod, Step,SmoothNo);
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
            for k=RefFrame-1:-1:min(Range)
                SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Outline'])) = CircleScanLivewire(SphinctalyzerOutputs(k).(matlab.lang.makeValidName([RefName,'Data'])),...
                    SphinctalyzerOutputs(k+1).(matlab.lang.makeValidName([RefName,'Data'])), SphinctalyzerOutputs(k+1).(matlab.lang.makeValidName([RefName,'Outline'])), 0, DetectionMethod, Step,SmoothNo);
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
