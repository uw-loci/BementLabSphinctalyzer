function saveAnalysisParameters(obj,savePath)
%save analysis parameters to a csv file
%input:
% obj: Image instance, include all the parameters for intitial analysis
% savePath: path to save analysis parameters

if nargin == 1
    parentFolderPath = pwd;
elseif nargin == 2
    parentFolderPath = savePath;
else
    error('Number of input arguments should be 1 or 2')
end
%save editable parameters into a csv file
csvfileName = 'parameters.csv';
parameters = obj;
propertiesList = properties(parameters);
propertiesLength = length(propertiesList);
[m,n] = size(parameters.cellArray); %m*n is the maximum number of values that one properties can contain
csvfileValue =  cell(propertiesLength,1+m*n);
for iP = 1:propertiesLength
    propertiesName = propertiesList{iP};
    csvfileValue{iP,1} = propertiesName;
    if isempty(find(strcmp(propertiesName,{'cellArray','axesNames','channelNames','moviePaths'}),1))
        if strcmp(propertiesName, 'channelColors') == 1
            csvfileValue{iP,2} = mat2str(parameters.(propertiesName){1});
            csvfileValue{iP,3} = mat2str(parameters.(propertiesName){2});
            csvfileValue{iP,4} = mat2str(parameters.(propertiesName){3});
        elseif strcmp(propertiesName, 'xMinStepMax') == 1
            csvfileValue{iP,2} = mat2str(parameters.(propertiesName));
        elseif strcmp(propertiesName, 'yMinStepMax') == 1
            csvfileValue{iP,2} = mat2str(parameters.(propertiesName));
        elseif strcmp(propertiesName, 'velocityStartStop') == 1
            csvfileValue{iP,2} = parameters.(propertiesName)(1);
            csvfileValue{iP,3} = parameters.(propertiesName)(2);
        else
            csvfileValue{iP,2} = parameters.(propertiesName);
        end
    else % for cell arrays: 'cellArray','axesNames','channelNames','moviePaths'
        [m,n] = size(parameters.(propertiesName));
        for iM = 1:m
            for iN = 1:n
                csvfileValue{iP,1+(iM-1)*n+iN} =  parameters.(propertiesName){iM,iN};
            end
        end
    end
end
%             writecell(csvfileValue, fullfile(parentFolderPath,csvfileName));
writecell(csvfileValue, fullfile(parentFolderPath,csvfileName));
save(fullfile(parentFolderPath,'parameters.mat'),'parameters','-mat');
fprintf('Analysis parameters files are saved to %s \n', parentFolderPath)