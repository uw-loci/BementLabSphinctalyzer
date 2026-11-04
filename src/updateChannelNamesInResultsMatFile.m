function [SphinctalyzerOutputs, message] = updateChannelNamesInResultsMatFile(obj,oldChannelNames,newChannelNames)
% update channel names in the sphinctalyzerResults.mat
% Input:
%     obj: Image instance of currrent oject
%     oldChannelNames: current channel names (the names saved in the .mat
%                      file are used, as they name the saved fields)
%     newChannelNames: new channel names, one per channel
% Output:
%     SphinctalyzerOutputs: updated results, [] if the file was not changed
%     message: what was done, or why the names were not changed
%
% Per-channel fields are named matlab.lang.makeValidName([channelName suffix])
% by the analysis, e.g. 'Portain A' -> 'PortainAOutline'. They are renamed by
% channel (not by replacing text), so names with spaces, hyphens or leading
% digits, partial renames and swapped names all work.
SphinctalyzerOutputs = [];
channelFieldSuffixes = {'Filename','Data','Outline','XDistances','MeanIntensities','IntensityStDev', ...
    'PointsPerGroup','MedianIntensities','SmoothIntensities','cpX','cpY'};

ParentFolderPath = fileparts(obj.filePath);
[ParentFolderPath] = fileparts(ParentFolderPath);
pathToResults = fullfile(ParentFolderPath,'sphincRedo','sphinctalyzerResults.mat');
SphincOutputs = load(pathToResults,'-regexp','^(InputCells|SphinctalyzerOutputs|UserDrawnBounds)$');
savedChannelNames = SphincOutputs.InputCells(:,1);
if nargin >= 2 && ~isempty(oldChannelNames) && ~isequal(cellstr(oldChannelNames(:)), savedChannelNames)
    fprintf('Channel names in the results .mat file (%s) are used as the current names \n', strjoin(savedChannelNames,', '))
end
oldChannelNames = savedChannelNames;
newChannelNames = cellfun(@(x) strtrim(char(x)), newChannelNames(:), 'UniformOutput', false);

% check the new names before changing anything
nChannels = numel(oldChannelNames);
if numel(newChannelNames) ~= nChannels
    message = sprintf('%d channel names were entered, but the results have %d channels.', numel(newChannelNames), nChannels);
    return
end
if any(cellfun(@isempty, newChannelNames))
    message = 'Channel names cannot be empty.';
    return
end
if numel(unique(newChannelNames)) < nChannels
    message = 'Channel names must be different from each other.';
    return
end
oldPrefixes = cellfun(@matlab.lang.makeValidName, oldChannelNames, 'UniformOutput', false);
newPrefixes = cellfun(@matlab.lang.makeValidName, newChannelNames, 'UniformOutput', false);
if numel(unique(newPrefixes)) < nChannels
    message = sprintf(['Channel names %s are too similar: they are stored under the same name (%s). ' ...
        'Use names that differ in letters or digits.'], strjoin(newChannelNames,', '), strjoin(newPrefixes,', '));
    return
end
if any(strcmpi(newChannelNames,'Self'))
    message = '"Self" cannot be used as a channel name.';
    return
end
if any(cellfun(@numel, newPrefixes) + max(cellfun(@numel, channelFieldSuffixes)) > namelengthmax)
    message = sprintf('Channel names must be shorter than %d characters.', namelengthmax - max(cellfun(@numel, channelFieldSuffixes)));
    return
end
if isequal(newChannelNames, oldChannelNames)
    message = 'Channel names are unchanged.';
    return
end

% map each field to its channel: longest matching channel prefix followed
% by a known suffix; other fields (RefChannel, InRange, ...) are kept as is
oldOutputs = SphincOutputs.SphinctalyzerOutputs;
oldFieldNames = fieldnames(oldOutputs);
newFieldNames = oldFieldNames;
for iField = 1:numel(oldFieldNames)
    fieldName = oldFieldNames{iField};
    bestChannel = 0;
    bestLength = 0;
    for iC = 1:nChannels
        prefix = oldPrefixes{iC};
        if startsWith(fieldName, prefix) && numel(prefix) > bestLength && ...
                any(strcmp(fieldName(numel(prefix)+1:end), channelFieldSuffixes))
            bestChannel = iC;
            bestLength = numel(prefix);
        end
    end
    if bestChannel > 0
        newFieldNames{iField} = [newPrefixes{bestChannel} fieldName(bestLength+1:end)];
    elseif ~any(strcmp(fieldName, {'RefChannel','InRange'}))
        fprintf('Field %s is not a channel field and is kept unchanged \n', fieldName)
    end
end
if numel(unique(newFieldNames)) < numel(newFieldNames)
    message = 'The new channel names would overwrite other saved results. Choose different names.';
    return
end

% build the renamed results
nFrames = numel(oldOutputs);
newCells = cell(numel(newFieldNames), nFrames);
for iField = 1:numel(oldFieldNames)
    [newCells{iField,:}] = oldOutputs.(oldFieldNames{iField});
end
SphinctalyzerOutputs = reshape(cell2struct(newCells, newFieldNames, 1), size(oldOutputs));
if any(strcmp(newFieldNames,'RefChannel'))
    for jFrame = 1:nFrames
        refChannel = SphinctalyzerOutputs(jFrame).RefChannel;
        isCellRef = iscell(refChannel);
        if isCellRef, refName = refChannel{1}; else, refName = refChannel; end
        iRef = find(strcmp(oldChannelNames, refName), 1);
        if ~isempty(iRef)  % 'Self' is kept
            if isCellRef, refChannel{1} = newChannelNames{iRef}; else, refChannel = newChannelNames{iRef}; end
            SphinctalyzerOutputs(jFrame).RefChannel = refChannel;
        end
    end
end
InputCells = SphincOutputs.InputCells;
InputCells(:,1) = newChannelNames;
savedVariables = {'InputCells','SphinctalyzerOutputs'};
if isfield(SphincOutputs,'UserDrawnBounds')
    UserDrawnBounds = SphincOutputs.UserDrawnBounds; %#ok<NASGU> saved below
    savedVariables{end+1} = 'UserDrawnBounds';
end

% back up and save
try
    pathToResults_bak = fullfile(ParentFolderPath,'sphinctalyzerResults_bak.mat');
    copyfile(pathToResults,pathToResults_bak)
    save(pathToResults,savedVariables{:});
catch saveError
    SphinctalyzerOutputs = [];
    message = sprintf('The results file could not be saved: %s', saveError.message);
    return
end
message = sprintf('Channel names changed from %s to %s.', strjoin(oldChannelNames,', '), strjoin(newChannelNames,', '));
fprintf('%s Results file: %s \n', message, pathToResults)
end
