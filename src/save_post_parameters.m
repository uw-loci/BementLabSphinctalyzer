function renameMessage = save_post_parameters(obj,advancedOptions,saveCommonFlag,moviePath)
%save post-processing parameters to an excel file
%input:
% obj: Image instance, include all the parameters for intitial analysis
% advancedOptions: parameters for peak,velocity,and closing calculation
% saveCommonFlag: 1: update all parameters; 2: only update specified common
% moviePath: path the results movie
%output:
% renameMessage: why the channel names in the results .mat file could not
% be changed ('' if they were changed or did not need changing)
% parameters
%save
%moviePath = obj.moviePaths{1};
foldermarkerIndex = strfind(moviePath,'sphincRedo');
postPath = moviePath(1:foldermarkerIndex-1);
savePath = postPath;
excelSavename = 'parameters_post.xlsx';
renameMessage = '';
parameters_post = cell(17,4); % add searchingRadius, closingCheckpoint, channelNames and closingCheckBasis

if saveCommonFlag ~= 1
    parameters_post{1,1} = 'Channel Colors';
    nColors = length(obj.channelColors);
    for i = 1:nColors
        parameters_post{1,i+1} = mat2str(obj.channelColors{i});
    end
    parameters_post{2,1} = 'Axes Names';
    nAxesNames = length(obj.axesNames);
    for i = 1:nAxesNames
        parameters_post{2,i+1} = obj.axesNames{i};
    end
    parameters_post{3,1} = 'DarkBackgroundFlag'; parameters_post{3,2} = obj.darkBackground;
    parameters_post{4,1} = 'SecondsPerFrame'; parameters_post{4,2} = obj.timePerFrame;
    parameters_post{5,1} = 'Normalization'; parameters_post{5,2} = obj.normalization;
    parameters_post{6,1} = 'Legend Location'; parameters_post{6,2} = obj.legendLocation;
    parameters_post{7,1} = 'MicronsPerPixel'; parameters_post{7,2} = obj.micronsPerPixel;
    parameters_post{8,1} = 'xMinStepMax'; parameters_post{8,2} = mat2str(obj.xMinStepMax);
    parameters_post{9,1} = 'yMinStepMax'; parameters_post{9,2} = mat2str(obj.yMinStepMax);
    parameters_post{10,1} = 'File Index'; parameters_post{10,2} = 1; %obj.movieIndex;
    parameters_post{11,1} = 'Image Filename'; parameters_post{11,2} = obj.imageName;
    parameters_post{12,1} = 'Results Folder'; parameters_post{12,2} = fullfile(savePath,'sphincRedo');%obj.savepath;

    parameters_post{13,1} = 'velocityStartStop';
    velocityStartStop_load = advancedOptions.velocityStartStop;
    if size(velocityStartStop_load,1) == 1
        parameters_post{13,2} = mat2str(velocityStartStop_load);
    elseif size(velocityStartStop_load,1) > 1
        for iC = 1: size(velocityStartStop_load,1)
            parameters_post{13,1+iC} = mat2str(velocityStartStop_load(iC,:));
        end
    else
        parameters_post{13,2} = num2str([1 2]);
    end
    parameters_post{14,1} = 'peak searching radius';parameters_post{14,2} = advancedOptions.peakSearchingRadius;
    parameters_post{15,1} = 'closing check point';parameters_post{15,2} = mat2str(advancedOptions.closingCheckpoint);
    if exist(fullfile(savePath, excelSavename),'file')
        delete(fullfile(savePath, excelSavename))
        fprintf('  deleted previous post-processing parameters file: \n     %s \n',fullfile(savePath, excelSavename))
    end
    parameters_post{16,1} = 'channelNames';
    nChannels = obj.nChannels;
    for i = 1:nChannels
        parameters_post{16,i+1} = obj.channelNames{i};
    end
    parameters_post{17,1} = 'closing check basis'; parameters_post{17,2} = closingCheckBasisOption(advancedOptions.closingCheckBasis);
    writecell(parameters_post,fullfile(savePath, excelSavename),'Sheet','parameters','Range','A1');
    fprintf('  created new post-processing parameters file: \n     %s \n',fullfile(savePath, excelSavename))
else  % save common parameters
    %get current saved post-processing parameters
    matFilePath = savePath;
   [processingParametersLoad, advancedOptionsLoad] = get_postParameters(matFilePath);
   % if channel name changed, ensure the channel names in the
   % sphinctalyzerResults.mat is updated.
   % update common parameters
    parameters_post{1,1} = 'Channel Colors';
    nColors = length(obj.channelColors);
    for i = 1:nColors
        parameters_post{1,i+1} = mat2str(obj.channelColors{i});
    end
    parameters_post{2,1} = 'Axes Names';
    nAxesNames = length(obj.axesNames);
    for i = 1:nAxesNames
        parameters_post{2,i+1} = obj.axesNames{i};
    end
    parameters_post{3,1} = 'DarkBackgroundFlag'; parameters_post{3,2} = obj.darkBackground;
    parameters_post{4,1} = 'SecondsPerFrame'; parameters_post{4,2} = obj.timePerFrame;
    parameters_post{5,1} = 'Normalization'; parameters_post{5,2} = obj.normalization;
    parameters_post{6,1} = 'Legend Location'; parameters_post{6,2} = obj.legendLocation;
    parameters_post{7,1} = 'MicronsPerPixel'; parameters_post{7,2} = obj.micronsPerPixel;
    parameters_post{8,1} = 'xMinStepMax'; parameters_post{8,2} = mat2str(obj.xMinStepMax); 
    parameters_post{9,1} = 'yMinStepMax'; parameters_post{9,2} = mat2str(obj.yMinStepMax); 
    parameters_post{10,1} = 'File Index'; parameters_post{10,2} = 1; %obj.movieIndex;
    obj.imageName = processingParametersLoad.imageName;% movie dependent
    parameters_post{11,1} = 'Image Filename'; parameters_post{11,2} = obj.imageName; 
    parameters_post{12,1} = 'Results Folder'; parameters_post{12,2} = fullfile(savePath,'sphincRedo');%obj.savepath;

    parameters_post{13,1} = 'velocityStartStop';
    velocityStartStop_load = advancedOptionsLoad.velocityStartStop; % movie dependent
    if size(velocityStartStop_load,1) == 1
        parameters_post{13,2} = mat2str(velocityStartStop_load);
    elseif size(velocityStartStop_load,1) > 1
        for iC = 1: size(velocityStartStop_load,1)
            parameters_post{13,1+iC} = mat2str(velocityStartStop_load(iC,:));
        end
    else
        parameters_post{13,2} = num2str([1 2]);
    end
    parameters_post{14,1} = 'peak searching radius';parameters_post{14,2} = advancedOptionsLoad.peakSearchingRadius; % movie dependent
    parameters_post{15,1} = 'closing check point';parameters_post{15,2} = mat2str(advancedOptions.closingCheckpoint);
    if exist(fullfile(savePath, excelSavename),'file')
        delete(fullfile(savePath, excelSavename))
        fprintf('  deleted previous post-processing parameters file: \n     %s \n',fullfile(savePath, excelSavename))
    end
    % if saved channel names are different from the current channel names
    % update the results file
     oldChannelNames = (processingParametersLoad.channelNames)'; %row -> col
     newChannelNames = obj.channelNames;
    if ~isequal(cellstr(oldChannelNames(:)), cellstr(newChannelNames(:)))
        [renamedOutputs, message] = updateChannelNamesInResultsMatFile(processingParametersLoad,oldChannelNames,newChannelNames);
        if isempty(renamedOutputs) && ~strcmp(message,'Channel names are unchanged.')
            renameMessage = message;
        end
    end
    parameters_post{16,1} = 'channelNames';
    nChannels = obj.nChannels;
    for i = 1:nChannels
        parameters_post{16,i+1} = obj.channelNames{i};
    end
    parameters_post{17,1} = 'closing check basis'; parameters_post{17,2} = closingCheckBasisOption(advancedOptions.closingCheckBasis);
    writecell(parameters_post,fullfile(savePath, excelSavename),'Sheet','parameters','Range','A1');
    fprintf('  created new post-processing parameters file: \n     %s \n',fullfile(savePath, excelSavename))

end