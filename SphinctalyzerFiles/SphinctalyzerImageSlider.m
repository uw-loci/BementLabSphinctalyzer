function SphinctalyzerImageSlider(BFcontrol, channelNames, ParentFolderPath, timePerFrame)
%visualize the image read by Bio-Formats(BF) with or without slider(s)
%input argument BFcontrol
set(0,'units','pixels');
windowSize = get(0,'ScreenSize');

%delete the exist BF-MAT figure 
BFfigure = findobj(0,'Tag','BF-MAT figure');
if ~isempty(BFfigure)
   delete(BFfigure); 
end

xlsSheets = cell(1,5);
xlsSheets{1} = xlsread(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Peak Intensity');
xlsSheets{2} = xlsread(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Peak Locations');
xlsSheets{3} = xlsread(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Halfwidths');
xlsSheets{4} = xlsread(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'AUCs');
xlsSheets{5} = xlsread(strcat(ParentFolderPath,'/sphincRedo/Results.xls'), 'Percent Above Background');

%initialize the slider current value
iSeries = BFcontrol.iSeries;
iChannel = BFcontrol.iChannel;
iTimepoint = BFcontrol.iTimepoint;
iFocalplane = BFcontrol.iFocalplane;

fullPath2image = fullfile(BFcontrol.imagePath,BFcontrol.imageName);
sliderName = {'Series','Channel','Timepoint','Focalplane'};
sliderObjects = cell(1,4);
maxSlider = [BFcontrol.seriesCount BFcontrol.nChannels BFcontrol.end BFcontrol.nFocalplanes]; % maximum value of each slider
flagSlider = [0 0 0 0]; % flags for 4 sliders for [series, channel, timepoints,
if BFcontrol.seriesCount> 1; flagSlider(1) = 1;  end% series
if BFcontrol.nChannels > 1; flagSlider(2) = 1; end % channels
if BFcontrol.nTimepoints > 1;flagSlider(3) = 1; end % time points
if BFcontrol. nFocalplanes > 1; flagSlider(4) = 1; end % focal planes

indexSlider = find(flagSlider>0);
if isempty(indexSlider)
    nSlider = 0;
    disp('No slider is needed for the dataset')
else
    nSlider = length(indexSlider);
    fprintf('Number of slider(s) to be displayed is %d \n', nSlider)
    for i = 1:nSlider
        fprintf('slider "%s" will stand for %s \n',sliderName{indexSlider(i)}(1),sliderName{indexSlider(i)});
    end
end
titleHeight = 0.025;  % normalized title height
sliderHeight = 0.025; % Normalized slider height;
imageAreaHeight = 1-titleHeight-(nSlider+1)*sliderHeight; %normalized image area size
imageAreaWidth = imageAreaHeight;
titleWidth = imageAreaWidth;
sliderWidth = imageAreaWidth;     % Normalized slider length
imageAreaX = (1-imageAreaWidth)/2;
imageAreaY = (nSlider+1)*sliderHeight;
titleX = imageAreaX+0.040;
titleY = imageAreaHeight+(nSlider+1)*sliderHeight; 

guiCtrl = figure('Position', [520*(windowSize(3)/1600) 200*(windowSize(3)/900) 800*(windowSize(3)/1600) 800*(windowSize(3)/900)], 'NumberTitle','off','Tag','BF-MAT figure',...
    'Name',sprintf('Bio-Formats MATLAB figure for %s:', BFcontrol.imageName));   % should be set with respect to the BF GUI position
imgPanel = uipanel('Parent', guiCtrl,'Units','normalized','Position',[0 0.25  1 0.75]);
fz1 = 10; % slider label size
fz2 = 11; % image title size

imgAx = axes('Parent',imgPanel,'YTick',[],'XTick',[],'Units','normalized',...
    'Position',[imageAreaX imageAreaY imageAreaWidth imageAreaHeight],'Tag','BF-MAT figureAX');
labelTitle = uicontrol('Parent',imgPanel,'Style','text','String',...
    BFcontrol.imageName,'Enable','on','HorizontalAlignment','left',...
    'FontSize',13,'Units','normalized','Position',[titleX titleY titleWidth titleHeight]);

dataPanel = uipanel('Parent',guiCtrl,'Units','normalized','Position',[0 0 1 0.25]);
table = zeros(length(channelNames), 6);
for i = 1:BFcontrol.nChannels
    for j = 1:6
        if j == 6
            peakLocationsSheet = xlsSheets{2};
            table(i, j) = (peakLocationsSheet(i + 1, BFcontrol.start) - peakLocationsSheet(i + 1, BFcontrol.end)) / ((BFcontrol.start - BFcontrol.end) * timePerFrame);
        else
            sheet = xlsSheets{j};
            table(i, j) = sheet(i + 1, BFcontrol.start);
        end
    end
end
sphincData = uitable('Parent',dataPanel, ...
    'ColumnName',{'Peak Intensity', 'Peak Locations', 'Halfwidths', 'AUCs', 'Percent Above Background', 'Wound Closing Velocity'}, ...
    'RowName', channelNames,...
    'Units','normalized', ...
    'Position',[0 0 1 1], ...
    'Data',table);

if nSlider == 0  
    bfRederinfo = bfGetReader(fullPath2image);
    bfRederinfo.setSeries(iSeries - 1);
    iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
    I = bfGetPlane( bfRederinfo, iPlane); 
    imagesc(I,'Parent',imgAx);
    set(imgAx,'YTick',[],'XTick',[]);
    colormap(imgAx,BFcontrol.colormap);
    axis image equal
    drawnow 
elseif nSlider > 0
    bfRederinfo = bfGetReader(fullPath2image);
    bfRederinfo.setSeries(iSeries - 1);
    iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
    I = bfGetPlane( bfRederinfo, iPlane); 
    imagesc(I,'Parent',imgAx);
    set(imgAx,'YTick',[],'XTick',[]);
    colormap(imgAx,BFcontrol.colormap);
    axis image equal
    drawnow 

% create slider(s)
    sliderWidth = imageAreaWidth;
    sliderX = imageAreaX;   
    sliderLabelSize = [0.0275 0.0275];
    sliderLabelX = sliderX-sliderLabelSize(1);
    for i = 1:nSlider   % 1. Series; 2 Channel; 3 Timepoint; 4 Focalplane.
        sliderY = (nSlider-i+1)*sliderHeight;   % Y coordinate of the slider starting point;
        sliderCreated = sliderName{indexSlider(i)};
        sliderMax = maxSlider(indexSlider(i));
        sliderMin = 1;
        sliderLabelY = sliderY;                  % Y coordinate of the slider label starting point;
        if strcmp (sliderCreated, 'Channel')
            sliderChannel = uicontrol('Parent',imgPanel,'Style','slide','Units',...
                'normalized','position',[sliderX sliderY sliderWidth sliderHeight],'min',sliderMin,'max',sliderMax,...
                'val',iChannel,'SliderStep', [1 1]/(sliderMax-sliderMin),'Enable','on');
            addlistener(sliderChannel,'ContinuousValueChange',@(hObject, event) updateImageChannel(hObject, event))
            sliderObjects{2} = sliderChannel;
        end
        if strcmp (sliderCreated, 'Timepoint')
            timeSliderMin = BFcontrol.start;
            sliderTimepoint = uicontrol('Parent',imgPanel,'Style','slide','Units',...
                'normalized','position',[sliderX sliderY sliderWidth sliderHeight],'min',timeSliderMin,'max',sliderMax,...
                'val',timeSliderMin,'SliderStep', [1 1]/(sliderMax-timeSliderMin),'Enable','on');
            addlistener(sliderTimepoint,'ContinuousValueChange',@(hObject, event) updateImageTimepoint(hObject, event));
            sliderObjects{3} = sliderTimepoint; 
        end
    end
    return
    
end


% %% plot the image
% % callback function for stack slider
%     function slider_chng_img(hObject,eventData,handles)
%         titleText = ''; seriesText = '';channelText = '';timepointText = '';focalplaneText = '';
%         if exist('sliderSeries','var'); 
%             iSeries = round(sliderSeries.Value);
%             titleText = sprintf('%s S:%d/%d ',titleText,iSeries,BFcontrol.seriesCount);
%             sliderObjects{1} = sliderSeries;
%         end
%         if exist('sliderChannel','var'); 
%             iChannel = round(sliderChannel.Value);
%             titleText = sprintf('%s C:%d/%d ',titleText,iChannel,BFcontrol.nChannels);
%             sliderObjects{2} = sliderChannel;
%             
%         end
%         if exist('sliderTimepoint','var'); 
%             iTimepoint = round(sliderTimepoint.Value); 
%             titleText = sprintf('%s T:%d/%d ',titleText,iTimepoint,BFcontrol.nTimepoints);
%             sliderObjects{3} = sliderTimepoint;
% 
%             for m = 1:BFcontrol.nChannels
%                 for n = 1:5
%                     sheet = xlsSheets{n};
%                     sphincData.Data(m, n) = sheet(m + 1, iTimepoint);
%                 end
%             end
%         end
%         if exist('sliderFocalplane','var'); 
%             iFocalplane = round(sliderFocalplane.Value); 
%             titleText = sprintf('%s F:%d/%d ',titleText,iFocalplane,BFcontrol.nFocalplanes);
%             sliderObjects{4} = sliderFocalplane;
%         end
%         bfRederinfo = bfGetReader(fullPath2image);
%         bfRederinfo.setSeries(iSeries - 1);
% 
%         iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
%         I = bfGetPlane(bfRederinfo, iPlane);
% 
%         imagesc(I,'Parent',imgAx);
%         set(labelTitle,'String',titleText);
%         set(imgAx,'YTick',[],'XTick',[]);
%         colormap(imgAx,BFcontrol.colormap);   
%         axis image equal
%         drawnow 
%     end

    function updateImageTimepoint(hObject,event)
        titleText = ''; seriesText = '';channelText = '';timepointText = '';focalplaneText = '';
        if exist('sliderTimepoint','var'); 
            iTimepoint = round(sliderTimepoint.Value); 
            titleText = sprintf('%s T:%d/%d ',titleText,iTimepoint,BFcontrol.nTimepoints);
            sliderObjects{3} = sliderTimepoint;

            for m = 1:BFcontrol.nChannels
                for n = 1:5
                    sheet = xlsSheets{n};
                    sphincData.Data(m, n) = sheet(m + 1, iTimepoint);
                end
            end
            set(hObject, 'val', iTimepoint)
        end

        bfRederinfo = bfGetReader(fullPath2image);
        bfRederinfo.setSeries(iSeries - 1);

        iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
        I = bfGetPlane(bfRederinfo, iPlane);

        imagesc(I,'Parent',imgAx);
        set(labelTitle,'String',titleText);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,BFcontrol.colormap);   
        axis image equal
        drawnow 
    end

    function updateImageChannel(hObject,event)
        titleText = ''; seriesText = '';channelText = '';timepointText = '';focalplaneText = '';
        if exist('sliderChannel','var'); 
            iChannel = round(sliderChannel.Value);
            titleText = sprintf('%s C:%d/%d ',titleText,iChannel,BFcontrol.nChannels);
            sliderObjects{2} = sliderChannel;
            set(hObject, 'val', iChannel)
        end

        bfRederinfo = bfGetReader(fullPath2image);
        bfRederinfo.setSeries(iSeries - 1);

        iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
        I = bfGetPlane(bfRederinfo, iPlane);

        imagesc(I,'Parent',imgAx);
        set(labelTitle,'String',titleText);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,BFcontrol.colormap);   
        axis image equal
        drawnow
    end
end