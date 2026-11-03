function [frames, status] = closingCheckpointFrames(measure, startFrame, endFrame, fractions)
% find the frame at which the wound is a given fraction open, for one channel
% input:
% measure: peak location (distance to wound center) or ring area, one value
%          per frame (NaN for frames without a peak)
% startFrame, endFrame: velocity start and end frames
% fractions: wound opening fractions, e.g. [0.667 0.500 0.333]
% output:
% frames: frame nearest to fraction*measure(startFrame) for each fraction,
%         NaN if no frame is within the average change between adjacent
%         frames, or if the range is not valid
% status: '' if the range is valid, otherwise why no frames were searched
frames = nan(numel(fractions),1);
status = '';
nFrames = numel(measure);
if ~isscalar(startFrame) || ~isscalar(endFrame) || any(isnan([startFrame endFrame])) || ...
        startFrame ~= round(startFrame) || endFrame ~= round(endFrame)
    status = 'velocity start and end frames are not whole numbers';
    return
end
if endFrame <= startFrame
    status = sprintf('velocity end frame (%d) is not after start frame (%d)', endFrame, startFrame);
    return
end
if startFrame < 1 || endFrame > nFrames
    status = sprintf('velocity range [%d %d] is outside the analyzed frames (1-%d)', startFrame, endFrame, nFrames);
    return
end
if isnan(measure(startFrame)) || isnan(measure(endFrame))
    status = sprintf('no peak was found at the velocity start (%d) or end (%d) frame', startFrame, endFrame);
    return
end
inRange = measure(startFrame:endFrame);
averageChange = abs((measure(startFrame)-measure(endFrame))/(endFrame-startFrame));
for cp = 1:numel(fractions)
    target = fractions(cp)*measure(startFrame);
    distances2checkpoint = abs(inRange - target);
    [minimumDistance, nearestIndex] = min(distances2checkpoint); % skips NaN frames; first (earliest) frame on ties
    if minimumDistance <= averageChange
        frames(cp) = startFrame + nearestIndex - 1;
        if nnz(distances2checkpoint == minimumDistance) > 1
            fprintf('  %d frames are equally close to the %3.1f%% checkpoint; the earliest (%d) is used \n', ...
                nnz(distances2checkpoint == minimumDistance), fractions(cp)*100, frames(cp));
        end
    end
end
end
