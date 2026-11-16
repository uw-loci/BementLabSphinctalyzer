function [files, numbers] = extraResultsFiles(postPath)
% Files of the post-processing results after the first in a results folder:
% for N >= 2 in sphincRedo, Results_N.xlsx, *_scan_movietalyzerResults_N.avi,
% saved data plots Results_N_*.tif, and their macOS "._" companion files.
% Results_1, sphinctalyzerResults.mat and all other files are not listed.
% files: full paths; numbers: the result numbers found (sorted, unique).
folder = fullfile(postPath,'sphincRedo');
listing = dir(folder);
listing = listing(~[listing.isdir]);
names = {listing.name};
patterns = {'^(\._)?Results_(\d+)\.xlsx$', ...
    '^(\._)?.*_scan_movietalyzerResults_(\d+)\.avi$', ...
    '^(\._)?Results_(\d+)_.*\.tif$'};
files = {};
numbers = [];
for i = 1:numel(names)
    for p = 1:numel(patterns)
        tokens = regexp(names{i}, patterns{p}, 'tokens', 'once');
        if ~isempty(tokens) && str2double(tokens{2}) >= 2
            files{end+1,1} = fullfile(folder, names{i}); %#ok<AGROW>
            numbers(end+1) = str2double(tokens{2}); %#ok<AGROW>
            break
        end
    end
end
numbers = unique(numbers);
end
