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
        imagePath
        nTimepoints
        colormap
        timePerFrame
        axesNames
        xMinStepMax
        yMinStepMax
        normalization
        micronsPerPixel
        imageActualPath
        imageName
        channelNames
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
                                imagePath,...
                                nTimepoints,...
                                colormap,...
                                timePerFrame,...
                                axesNames,...
                                xMinStepMax,...
                                yMinStepMax, ...
                                normalization, ...
                                micronsPerPixel, ...
                                imageActualPath, ...
                                imageName, ...
                                channelNames)
                    obj.cellArray = cellArray;
                    obj.timepointStart = timepointStart;
                    obj.timepointEnd = timepointEnd;
                    obj.speed = speed;
                    obj.loadMulti = loadMulti;
                    obj.shape = shape;
                    obj.detection = detection;
                    obj.smooth = smooth;
                    obj.step = step;
                    obj.imagePath = imagePath;
                    obj.nTimepoints = nTimepoints;
                    obj.colormap = colormap;
                    obj.timePerFrame = timePerFrame;
                    obj.axesNames = axesNames;
                    obj.xMinStepMax = xMinStepMax;
                    obj.yMinStepMax = yMinStepMax;
                    obj.normalization = normalization;
                    obj.micronsPerPixel = micronsPerPixel;
                    obj.imageActualPath = imageActualPath;
                    obj.imageName = imageName;
                    obj.channelNames = channelNames;
        end
    end
end