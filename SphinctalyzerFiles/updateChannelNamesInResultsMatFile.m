function SphinctalyzerOutputs = updateChannelNamesInResultsMatFile(obj,oldChannelNames,newChannelNames)
% update channel names in the sphinctalyzerResults.mat
% Input: 
%     obj: Image instance of currrent oject
%     oldChannelNames: current channel names
%     newChannelNames: new channel names

        if strcmp(oldChannelNames,newChannelNames)== 1
           SphinctalyzerOutputs = [];
           return
        end
        % 
        disp('Changing the channel names in the results .mat file')
        ParentFolderPath = fileparts(obj.filePath);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        referenceArray = [obj.cellArray{:,3}];
        % load in SphinctalyzerOutputs data structure
        pathToResults = strcat(ParentFolderPath,'/sphincRedo/sphinctalyzerResults.mat');
        pathToResults_bak = strrep(pathToResults,'sphincRedo/sphinctalyzerResults.mat','sphinctalyzerResults_bak.mat');
        copyfile(pathToResults,pathToResults_bak)
        SphincOutputs_old = load(pathToResults,'InputCells', 'SphinctalyzerOutputs','UserDrawnBounds');
        SphincOutputs = SphincOutputs_old;
        channelNamesInMat = SphincOutputs_old.InputCells(:,1); 
        % change the channel namke in the InputCells
        InputCells = obj.cellArray; 
        InputCells(:,1) = newChannelNames; % update the names in the obj.cellArray
        UserDrawnBounds = SphincOutputs.UserDrawnBounds;
        if ~strcmp(channelNamesInMat,oldChannelNames)  % the channel names can be get from post/pre/excelfile/
            oldChannelNames = channelNamesInMat; % use the channel names in the mat file to match the output names
        end
        SphinctalyzerOutputs = SphincOutputs.SphinctalyzerOutputs;
        nFrames = size(SphinctalyzerOutputs,2); % number of frames
        oldFieldNames =fieldnames(SphincOutputs.SphinctalyzerOutputs);
        newFieldNames = oldFieldNames;

       
        
        for i = 1:obj.nChannels
            oldChannelName = oldChannelNames{i};
            newChannelName = newChannelNames{i};
            newFieldNames = strrep(newFieldNames, oldChannelName, newChannelName);
        end
        nFields = length(oldFieldNames);

        for iField = 1: nFields
            for jFrames = 1: nFrames
                SphinctalyzerOutputs(jFrames).(newFieldNames{iField}) = SphinctalyzerOutputs(jFrames).(oldFieldNames{iField});
            end
        end
        referenceChannel = find(referenceArray == 1);
        if ~isempty(referenceChannel) & length(referenceChannel) == 1
            for jFrame = 1:nFrames
                SphinctalyzerOutputs(jFrame).RefChannel = strrep( SphinctalyzerOutputs(jFrame).RefChannel, ...
                    oldChannelNames{referenceChannel}, newChannelNames{referenceChannel});
            end
            disp('Reference channel name in the results .mat file will be updated. ')
        else
            disp('Reference channel name in the results .mat file will NOT be updated ')
        end
        % Keep two fields RefChannel and 'InRange' in the updated new
        % output
        fieldKeep1 = find(strcmp(oldFieldNames,'RefChannel'));
        fieldKeep2 = find(strcmp(oldFieldNames,'InRange'));
        oldFieldNames([fieldKeep1 fieldKeep2]) = [];
        %compare oldFieldNames and newFieldNames
        %check which element of oldFieldNames are in newFieldNames
        inNewNames = find(ismember(oldFieldNames,newFieldNames) == 1);
        if ~isempty(inNewNames)
            disp(['The oldFieldNames variable has same elements as the newFieldNames, ...' ...
                'quit results .MAT file update']) 
            return
        end
        SphinctalyzerOutputs = rmfield(SphinctalyzerOutputs,oldFieldNames);
        % update the results .mat file
        save(pathToResults,'InputCells', 'SphinctalyzerOutputs','UserDrawnBounds');
        fprintf('Channel names are updated in the results file of %s \n', pathToResults)
        return 
    end