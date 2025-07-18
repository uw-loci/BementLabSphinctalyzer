function SphincRescue(ParentFolderPath,speed,loadMulti,shape,detection,step,runInBackgroundFlag)
if nargin == 0
    guiInput = 0;
    speed = 0;
    loadMulti = 0;
    shape = 0;
    detection = 0;
    step = 0;
    runInBackgroundFlag = 0;
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
    OutlinerFolderLoader(path{i},speed,loadMulti,shape,detection,step, guiInput,runInBackgroundFlag);
end

function OutlinerFolderLoader(path,speed,loadMulti,shape,detection,step, guiInput,runInBackgroundFlag)

%Run Program on any applicable files in path
validnames=dir(fullfile(path, '*.mat'));
for i=1:size(validnames,1)
    CurrentName=validnames(i).name;
    if ~isempty(findstr(CurrentName,'sphinc'))
        if guiInput == 1
            SphinctalyzerInitialized(validnames(i).name,path,speed,loadMulti,shape,detection,step,runInBackgroundFlag);
        else
            SphinctalyzerInitialized(validnames(i).name,path)
        end
    end
end
%check for subdirectories
allnames=dir(path);
allnames(~[allnames.isdir]) = [];  %remove non-directories
tf = ismember( {allnames.name}, {'.', '..'});
allnames(tf) = [];  %remove current and parent directory.
for i=1:size(allnames,1)
    OutlinerFolderLoader(fullfile(path,allnames(i).name),speed,loadMulti,shape,detection,step, guiInput,runInBackgroundFlag);
end
