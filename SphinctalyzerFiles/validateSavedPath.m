function [reuseSavedPath, UserDrawnBounds, saveFileName] = validateSavedPath(imgName, refChannelName, framePosition, colorMap, figAnnotation)

%% VALIDATESAVEDPATH
%   Checks if a saved path can be reused based on image, reference channel, and frame position.
%   [REUSESAVEDPATH, USERDRAWNBOUNDS, SAVEFILENAME] = VALIDATESAVEDPATH(IMGNAME, REFCHANNELNAME, FRAMEPOSITION)
%   Checks if a saved path exists for the current IMGNAME, REFCHANNELNAME, and FRAMEPOSITION.
%   Prompts the user to reuse or redraw the path if a match is found.
%
%   INPUTS:
%       imgName        - Current image name.
%       refChannelName - Reference channel for validation.
%       framePosition  - Frame position for validation.
%       colorMap       - Colormap for image visualization.
%       figAnnotation  - Figure handle for image display.
%
%   OUTPUTS:
%       reuseSavedPath   - True if the saved path is reused, false otherwise.
%       UserDrawnBounds  - The reused path if valid, or empty if a new path is drawn.
%       saveFileName     - The name of the saved path file.
% 
%   Looks for saved paths in 'test_datasets/Sphincdata' and prompts the user to reuse or redraw if a valid path is found.
%%

baseOutputPath = fullfile(pwd, '..', 'test_datasets', 'Sphincdata');

if ~exist(baseOutputPath, 'dir')
    mkdir(baseOutputPath);
end

saveFileName = fullfile(baseOutputPath, sprintf('SavedPath_%s_ref_[%s]_framePosition_[%d].mat', imgName, refChannelName, framePosition));

reuseSavedPath = false;
UserDrawnBounds = [];

if exist(saveFileName, 'file')
    disp('Saved path file found');
    savedData = load(saveFileName, 'UserDrawnBounds', 'imgName', 'refChannelName', 'framePosition');

    if strcmp(savedData.imgName, imgName) && strcmp(savedData.refChannelName, refChannelName) && savedData.framePosition == framePosition
        choice = questdlg('A saved path exists for this image. Would you like to reuse it or draw a new one?', ...
            'Saved Path Found', 'Reuse Saved Path', 'Draw New Path', 'Reuse Saved Path');
        if strcmp(choice, 'Reuse Saved Path')
            UserDrawnBounds = savedData.UserDrawnBounds;
            disp('Reusing the saved path.');
            reuseSavedPath = true;
        else
            disp('User chose to draw a new path.');
        end
    else
        disp('Saved path does not match the current movie name, reference channel, or frame position.');
    end
else
    disp('No saved path found, proceeding to draw a new one.');
end
end
