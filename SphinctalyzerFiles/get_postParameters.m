
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
%%
matFileName = 'parameters.mat';
resultsFileName = 'Results_1.xlsx';
postParametersFileName = 'parameters_post.xlsx';
parameterFilePath = matFilePath;
parameterFileName = matFileName;
load(fullfile(parameterFilePath,parameterFileName),"parameters");
obj = parameters;

resultsFilePath = fullfile(matFilePath,'sphincRedo'); % resultsFilePath: path to the Results_1.xlsx file
if ~exist(fullfile(matFilePath,postParametersFileName),'file')
    if exist(fullfile(resultsFilePath,resultsFileName),'file')
        post_parameters = readcell(fullfile(resultsFilePath,resultsFileName),'Sheet','parameters');
        % maskedPattern = cellfun(@ismissing,post_parameters,'UniformOutput',false);
        maskedPattern = cellfun(@(x)any(isa(x,'missing')),post_parameters,'UniformOutput',false);
        post_parameters(find(cell2mat(maskedPattern)== 1))= {[]};
        writecell(post_parameters,fullfile(matFilePath,postParametersFileName),'Sheet','parameters');
        fprintf('created a post-process parameters file based on the results_1 parameters \n')
    else
        fprintf('No post_parameters file was found, using the default parameters for the post-processing')
        processingParameters = obj;
        if size(obj.velocityStartStop,1) == 1
            obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
        end
        advancedOptions.velocityStartStop =obj.velocityStartStop;
        advancedOptions.peakSearchingRadius = 0;
        advancedOptions.closingCheckpoint= [0.667 0.500 0.333];
        return
    end
end
try
    post_parameters = readcell(fullfile(parameterFilePath,postParametersFileName),'Sheet','parameters');
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
    if size(movieOptions,1) == 12
        movieOptions{13,1} = 'velocityStartStop';
        movieOptions{13,2} = obj.velocityStartStop;
    end

    if size(movieOptions,1) == 13
        if size(obj.velocityStartStop,1) == 1
            obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
        end
        advancedOptions.velocityStartStop =obj.velocityStartStop;
        advancedOptions.peakSearchingRadius = 0;
        advancedOptions.closingCheckpoint= [0.667 0.500 0.333];
    elseif size(movieOptions,1) >= 15
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
        if size(movieOptions,1) == 16
            movieOptions{16,1} = 'channelNames';
            movieOptions{16,2} = obj.channelNames;
        end

    end
    processingParameters = obj;

catch exp_post
    fprintf('  post-processing, parameters error: %s \n ',exp_post.message )
    % post_parameters = cell(15,4);
    processingParameters = obj;
    if size(obj.velocityStartStop,1) == 1
        obj.velocityStartStop = repmat(obj.velocityStartStop,obj.nChannels,1);
    end
    advancedOptions.velocityStartStop =obj.velocityStartStop;
    advancedOptions.peakSearchingRadius = 0;
    advancedOptions.closingCheckpoint= [0.667 0.500 0.333];
end

end
