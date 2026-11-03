classdef Image
    % Image data for sphinctalyzation

    properties
        cellArray
        timepointStart
        timepointEnd
        speed
        loadMulti
        shape
        detection
        smooth
        step
        filePath
        nTimepoints
        nChannels
        colormap
        timePerFrame
        axesNames
        xMinStepMax
        yMinStepMax
        normalization
        micronsPerPixel
        imagePath
        imageName
        channelNames
        channelColors
        darkBackground
        legendLocation
        roiShape
        batchDirectory
        moviePaths
        velocityStartStop
    end

    methods
        function obj = Image(cellArray,...
                                timepointStart,...
                                timepointEnd,...
                                speed,...
                                loadMulti,...
                                shape,...
                                detection,...
                                smooth,...
                                step,...
                                filePath,...
                                nTimepoints,...
                                colormap,...
                                timePerFrame,...
                                axesNames,...
                                xMinStepMax,...
                                yMinStepMax, ...
                                normalization, ...
                                micronsPerPixel, ...
                                imagePath, ...
                                imageName, ...
                                channelNames, ...
                                channelColors, ...
                                darkBackground, ...
                                legendLocation, ...
                                roiShape, ...
                                batchDirectory, ...
                                moviePaths, ...
                                velocityStartStop)
                    obj.cellArray = cellArray;
                    obj.timepointStart = timepointStart;
                    obj.timepointEnd = timepointEnd;
                    obj.speed = speed;
                    obj.loadMulti = loadMulti;
                    obj.shape = shape;
                    obj.detection = detection;
                    obj.smooth = smooth;
                    obj.step = step;
                    obj.filePath = filePath;
                    obj.nTimepoints = nTimepoints;
                    obj.colormap = colormap;
                    obj.timePerFrame = timePerFrame;
                    obj.axesNames = axesNames;
                    obj.xMinStepMax = positiveXMinStepMax(xMinStepMax); % convert legacy negative x axis
                    obj.yMinStepMax = yMinStepMax;
                    obj.normalization = normalization;
                    obj.micronsPerPixel = micronsPerPixel;
                    obj.imagePath = imagePath;
                    obj.imageName = imageName;
                    obj.channelNames = channelNames;
                    obj.channelColors = channelColors;
                    obj.darkBackground = darkBackground;
                    obj.legendLocation = legendLocation;
                    obj.roiShape = roiShape;
                    obj.batchDirectory = batchDirectory;
                    obj.moviePaths = moviePaths;
                    obj.velocityStartStop = velocityStartStop;
        end
    end
end