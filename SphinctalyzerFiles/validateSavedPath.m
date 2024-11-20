function [reuseSavedPath, UserDrawnBounds, saveFileName] = validateSavedPath(imgPath, imgName, refChannelName, framePosition, colorMap, figAnnotation,refImageData,chIndex)

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
%       refImageData   - image data of the reference frame
%       chIndex        - index to the reference channel
%
%   OUTPUTS:
%       reuseSavedPath   - True if the saved path is reused, false otherwise.
%       UserDrawnBounds  - The reused path if valid, or empty if a new path is drawn.
%       saveFileName     - The name of the saved path file.
% 
%   Looks for saved paths in 'test_datasets/Sphincdata' and prompts the user to reuse or redraw if a valid path is found.
%%

baseOutputPath = fullfile(imgPath, 'Sphincdata');

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
        %show previous path
        figure(figAnnotation);
        title('Previous annotated brightest path')
        hold on
        boundaryXY = bwboundaries(savedData.UserDrawnBounds(chIndex).BWMaskOut,4,'CoordinateOrder','xy');
        boundaryXYc(:,1) = [boundaryXY{1}(:,1);boundaryXY{1}(1,1)];
        boundaryXYc(:,2) = [boundaryXY{1}(:,2);boundaryXY{1}(1,2)];
        % drawpolygon('Position',boundaryXY{1},'color','r','FaceAlpha' ,0.1);
        plot(boundaryXYc(:,1),boundaryXYc(:,2),'color','r','LineWidth',2);
        hold off
        choice = questdlg('A saved path exists for this image. Would you like to reuse it or draw a new one?', ...
            'Saved Path Found', 'Reuse Saved Path', 'Draw New Path', 'Reuse Saved Path');
        if strcmp(choice, 'Reuse Saved Path')
            UserDrawnBounds = savedData.UserDrawnBounds;
            disp('Reusing the saved path.');
            reuseSavedPath = true;
        else
            disp('User chose to draw a new path.');
            figure(figAnnotation)
            imagesc(refImageData); %display image
            colormap (colorMap)
            axis image
            title('Trace the brightest path, then double click inside the ROI')  
        end
    else
        disp('Saved path does not match the current movie name, reference channel, or frame position.');
    end
else
    disp('No saved path found, proceeding to draw a new one.');
end
end
