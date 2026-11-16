function n = nextResultsIndex(postPath)
% Number for new post-processing results in a results folder: 1 + the
% highest <n> among sphincRedo/Results_<n>.xlsx and
% sphincRedo/*_scan_movietalyzerResults_<n>.avi (1 if there are none).
% macOS "._" metadata files are ignored.
files = [dir(fullfile(postPath,'sphincRedo','Results_*.xlsx')); ...
    dir(fullfile(postPath,'sphincRedo','*_scan_movietalyzerResults_*.avi'))];
names = {files.name};
names(strncmp(names,'._',2)) = [];
numbers = regexp(names, '_(\d+)\.(xlsx|avi)$', 'tokens', 'once');
numbers = numbers(~cellfun(@isempty, numbers));
if isempty(numbers)
    n = 1;
else
    n = max(cellfun(@(t) str2double(t{1}), numbers)) + 1;
end
end
