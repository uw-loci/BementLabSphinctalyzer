function [reuseSavedPath, UserDrawnBounds, saveFileName] = validateSavedPath(imgName, refChannelName, framePosition, colorMap, figAnnotation)

% FIXED OUTPUT PATH: Ensure all outputs go to the correct directory in GitHub/BementLabSphinctalyzer/test_datasets/Sphincdata
baseOutputPath = fullfile(pwd, '..', 'test_datasets', 'Sphincdata');

% Ensure the baseOutputPath exists
if ~exist(baseOutputPath, 'dir')
    mkdir(baseOutputPath);  % Create the directory if it doesn't exist
end

% Define the full path for saving/loading the user-drawn ROI based on imgName, reference channel, and frame position
saveFileName = fullfile(baseOutputPath, sprintf('SavedPath_%s_ref_[%s]_framePosition_[%d].mat', imgName, refChannelName, framePosition));

% Initialize the return values
reuseSavedPath = false;
UserDrawnBounds = [];

% Check if a previously saved path exists for the current image
if exist(saveFileName, 'file')
    disp('Saved path file found');
    % Load the saved path
    savedData = load(saveFileName, 'UserDrawnBounds', 'imgName', 'refChannelName', 'framePosition');

    % Validate the saved path by matching movie name (imgName), reference channel, and frame position
    if strcmp(savedData.imgName, imgName) && strcmp(savedData.refChannelName, refChannelName) && savedData.framePosition == framePosition
        % Ask the user whether to reuse the saved path or draw a new one
        choice = questdlg('A saved path exists for this image. Would you like to reuse it or draw a new one?', ...
            'Saved Path Found', 'Reuse Saved Path', 'Draw New Path', 'Reuse Saved Path');
        if strcmp(choice, 'Reuse Saved Path')
            % If the user chooses to reuse the saved path, return the saved bounds
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
