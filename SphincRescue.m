function SphincRescue(ParentFolderPath)
if nargin == 0
    guiInput = 0;
else
    guiInput = 1;
end

h='Yes';
i=2;
path={};
if guiInput == 0
    path{1}=uigetdir;
else
    path{1} = ParentFolderPath;
end
for i=1:length(path)
    OutlinerFolderLoader(path{i});
end

function OutlinerFolderLoader(path)

%Run Program on any applicable files in path
validnames=dir(fullfile(path, '*.mat'));
for i=1:size(validnames,1)
    CurrentName=validnames(i).name;
    if ~isempty(findstr(CurrentName,'sphinc'))
    SphinctalyzerInitialized(validnames(i).name,path);
    end
end
%check for subdirectories
allnames=dir(path);
allnames(~[allnames.isdir]) = [];  %remove non-directories
tf = ismember( {allnames.name}, {'.', '..'});
allnames(tf) = [];  %remove current and parent directory.
for i=1:size(allnames,1)
    OutlinerFolderLoader(fullfile(path,allnames(i).name));
end
