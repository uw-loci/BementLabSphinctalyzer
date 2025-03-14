
function [processingParameters, advancedOptions] = get_postParameters(matFilePath)
%use the post-processing parameters in the results file to update mat
%parameters and advancedOptions parameters
% input:
% matFilePath: path to the parameters.mat
% saveFlag: save into the output file
%output:
%processingParameters: Image class, parameters used for the analysis
%advancedOption: added post-processing parameters for peak, velocity and
%closing calculation

% parameters in the results file
% parameters_post{3,1} = 'DarkBackgroundFlag'; parameters_post{3,2} = darkBackgroundFlag;
% parameters_post{4,1} = 'SecondsPerFrame'; parameters_post{4,2} = secondsPerFrame;
% parameters_post{5,1} = 'Normalization'; parameters_post{5,2} = normalization;
% parameters_post{6,1} = 'Legend Location'; parameters_post{6,2} = legendLocation;
% parameters_post{7,1} = 'MicronsPerPixel'; parameters_post{7,2} = micronsPerPixel;
% parameters_post{8,1} = 'xMinStepMax'; parameters_post{8,2} = mat2str(xMinStepMax);
% parameters_post{9,1} = 'yMinStepMax'; parameters_post{9,2} = mat2str(yMinStepMax);
% parameters_post{10,1} = 'File Index'; parameters_post{10,2} = num;
% parameters_post{11,1} = 'Image Filename'; parameters_post{11,2} = imageFileName;
% parameters_post{12,1} = 'Results Folder'; parameters_post{12,2} = savepath;
% parameters_post{13,1} = 'velocityStartStop';
% velocityStartStop_load = advancedOptions.velocityStartStop;
% if size(velocityStartStop_load,1) == 1
%     parameters_post{13,2} = mat2str(velocityStartStop_load);
% elseif size(velocityStartStop_load,1) > 1
%     for iC = 1: size(velocityStartStop_load,1)
%         parameters_post{13,1+iC} = mat2str(velocityStartStop_load(iC,:));
%     end
% else
%     parameters_post{13,2} = num2str([1 2]);
% end
% parameters_post{14,1} = 'peak searching radius';parameters_post{14,2} = advancedOptions.peakSearchingRadius;
% parameters_post{15,1} = 'closing check point';parameters_post{15,2} = mat2str(advancedOptions.closingCheckpoint);
% writecell(parameters_post,[savepath, excelSavename],'Sheet','parameters','Range','A1');

%parameters in the mat file
% classdef Image
%     % Image data for sphinctalyzation
%
%     properties
%         cellArray
%         timepointStart
%         timepointEnd
%         speed
%         loadMulti
%         shape
%         detection
%         smooth
%         step
%         filePath
%         nTimepoints
%         nChannels
%         colormap
%         timePerFrame
%         axesNames
%         xMinStepMax
%         yMinStepMax
%         normalization
%         micronsPerPixel
%         imagePath
%         imageName
%         channelNames
%         channelColors
%         darkBackground
%         legendLocation
%         roiShape
%         batchDirectory
%         moviePaths
%         velocityStartStop
%     end
%
% end
%%
% matFilePath = 'H:\GitHub.06.2022\BementLabSphinctalyzer\test_datasets\Sphincdata\Output_13-Mar-2025_14-51-32\data_sphintest_1channelNonUniformRing.tif'
matFileName = 'parameters.mat';
resultsFileName = 'results_1.xlsx';
parameterFilePath = matFilePath;
parameterFileName = matFileName;

load(fullfile(parameterFilePath,parameterFileName),"parameters");
obj = parameters;
resultsFilePath = fullfile(matFilePath,'sphincRedo',resultsFileName); % resultsFilePath: path to the Results_1.xlsx file
try
    post_parameters = readcell(fullfile(resultsFilePath,resultsFileName),'Sheet','parameters');
    movieOptions =post_parameters;
    %advancedOptions = struct('peakSearchingRadius',0,'velocityStartStop',[],'closingCheckpoint',[0.667 0.500 0.333]);
    obj.darkBackground = movieOptions{3,2};
    obj.normalization = movieOptions{5,2};
    obj.legendLocation = movieOptions{6,2};
    obj.micronsPerPixel = movieOptions{7,2};
    obj.timePerFrame = movieOptions{4,2};
    for iC = 1:obj.nChannels
        obj.channelColors{iC} = str2num(movieOptions{1,iC+1});
    end
    obj.axesNames = movieOptions(2,2:3);
    obj.xMinStepMax = str2num(movieOptions{8,2});
    obj.yMinStepMax = str2num(movieOptions{9,2});
    velocityRanges = {enterVelocityRangeC1 enterVelocityRangeC2 enterVelocityRangeC3};
    if size(movieOptions,1) == 13
        if size(obj.velocityStartStop,1) == 1
            obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
        end
        advancedOptions.velocityStartStop =obj.velocityStartStop;
        advancedOptions.peakSearchingRadius = 0;
        advancedOptions.closingCheckpoint= [0.667 0.500 0.333];
    elseif size(movieOptions,1) == 15
        for iC = 1:obj.nChannels
            advancedOptions.velocityStartStop(iC,:) = str2num(movieOptions{13,1+iC});
        end
        advancedOptions.peakSearchingRadius = movieOptions{14,2};
        try
            advancedOptions.closingCheckpoint = str2num(movieOptions{15,2});
        catch
            advancedOptions.closingCheckpoint = movieOptions{15,2};
        end
        fprintf('number of closing checkpoint(s) is %d \n', size(advancedOptions.closingCheckpoint,2))

    end
    processingParameters = obj;

catch exp_post
    fprintf('  post-processing, parameters error: %s \n ',exp_post.message )
    post_parameters = cell(15,4);
    processingParameters = obj;
    if size(obj.velocityStartStop,1) == 1
        obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
    end
    advancedOptions.velocityStartStop =obj.velocityStartStop;
    advancedOptions.peakSearchingRadius = 0;
    advancedOptions.closingCheckpoint= [0.667 0.500 0.333];
end

% parameters = load(fullfile(parameterFilePath,parameterFileName));
% names = fieldnames(parameters);
% name = names(1);
% if ~isequal(class(parameters.(name{1})),'Image')
%     errordlg('Please load a valid parameters file.');
% else
%     matfileName = parameterFileName;
%     parametersOld = parameters;%load(matfileName);
%     parametersLoad = readcell(fullfile(resultsFilePath,resultsFilename));
%     parameters = parametersOld.parameters;
%     %                 parametersUpdate = parameters;
%     propertiesList = properties(parameters);
%     propertiesLength = length(propertiesList);
%     [m,n] = size(parameters.cellArray); %m*n is the maximum number of values that one properties can contain
%     propertyValue =  cell(propertiesLength,1+m*n);
%     for iP = 1:propertiesLength
%         propertiesName = propertiesList{iP};
%         propertyValue{iP,1} = propertiesName;
%         if isempty(find(strcmp(propertiesName,{'cellArray','axesNames','channelNames','moviePaths'}),1))
%             if strcmp(propertiesName, 'channelColors') == 1
%                 parameters.(propertiesName){1} = str2num(parametersLoad{iP,2});
%                 parameters.(propertiesName){2} = str2num(parametersLoad{iP,3});
%                 parameters.(propertiesName){3} = str2num(parametersLoad{iP,4});
%             elseif strcmp(propertiesName, 'xMinStepMax') == 1
%                 parameters.(propertiesName) = str2num(parametersLoad{iP,2});
%             elseif strcmp(propertiesName, 'yMinStepMax') == 1
%                 parameters.(propertiesName) = str2num(parametersLoad{iP,2});
%             elseif strcmp(propertiesName, 'velocityStartStop') == 1
%                 parameters.(propertiesName) = [parametersLoad{iP,2} parametersLoad{iP,3}];
%             else
%                 parameters.(propertiesName) = parametersLoad{iP,2};
%             end
%         else % for cell arrays: 'cellArray','axesNames','channelNames','moviePaths'
%             [m,n] = size(parameters.(propertiesName));
%             parametersCell = cell(m,n);
%             for iM = 1:m
%                 for iN = 1:n
%                     parameters.(propertiesName){iM,iN} = parametersLoad{iP,1+(iM-1)*n+iN};
%                 end
%             end
% 
%         end
%     end
%     % save .mat parameters
%     %                 [ParentFolderPath] = fileparts(ParentFolderPath);
%     % save(fullfile(parameterFilePath,parameterFileName),'parameters','-mat');
%     fprintf('Parameter file %s is loaded from %s \n',resultsFilePath, parameterFilePath)
%     fprintf('This file will be applied to subsequently loaded images. \n')
%     loadParameters = 1;
%     set(loadParam,'Enable','off')
%     fprintf('"Load Parameters" button is disabled. \n To load a new parameters file, click on the "Reset" button to start over. \n' )
%     msgbox("Parameters successfully loaded.");
% end
% processingParameters = parameters;
% advancedOptions =


end
