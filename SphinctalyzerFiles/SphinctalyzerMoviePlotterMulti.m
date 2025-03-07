function SphinctalyzerMoviePlotterMulti(ParentFolderPath, ...
    channelColors,axesNames,darkBackgroundFlag,secondsPerFrame,normalization,legendLocation, micronsPerPixel, ...
    xMinStepMax, ...
    yMinStepMax, ...
    num, ...
    imageFileName,...
    velocityStartStop)
    if nargin == 0
        guiInput = 0;
        channelColors = 0;
        axesNames = 0;
        darkBackgroundFlag = 0;
        secondsPerFrame = 0;
        normalization = 0;
        legendLocation = 'NorthWest';
        micronsPerPixel = 1; %if 1, will display x axis in pixels.  All other values convert to microns
        xMinStepMax = 0;
        yMinStepMax = 0;
        num = 0;
        imageFileName = 0;
        obj.velocityStartStop = [1 2];
    else 
        guiInput = 1;
    end
    
    validnames=dir(fullfile([pwd,'/poi_library'], '*.jar'));
    for i=1:size(validnames,1)
        javaaddpath(fullfile([pwd,'/poi_library'],validnames(i).name));
    end
    h='Yes';
   % i=2;
    path={};
    if guiInput == 0
        path{1}=uigetdir;
    elseif guiInput == 1
        path{1}=ParentFolderPath;
    end
    for i=1:length(path)
        OutlinerFolderLoader(path{i}, ...
            channelColors,axesNames,darkBackgroundFlag,guiInput,secondsPerFrame,normalization,legendLocation, micronsPerPixel, ...
            xMinStepMax, ...
            yMinStepMax, ...
            num, ...
            imageFileName,...
            velocityStartStop);
    end
end


function LineNo=OutlinerFolderLoader(path, ...
    channelColors,axesNames,darkBackgroundFlag,guiInput,secondsPerFrame,normalization,legendLocation, micronsPerPixel, ...
    xMinStepMax, ...
    yMinStepMax, ...
    num, ...
    imageFileName,...
    velocityStartStop)

%Run Program on any applicable files in path
if ~isempty(findstr(path, 'sphincRedo'))
validnames=dir(fullfile(path, '*.mat'));
    LineNo=2;
    for i=1:size(validnames,1)
        CurrentName=validnames(i).name;
        if ~isempty(findstr(CurrentName,'sphinc'))
            LineNo=SphinctalyzerMP(validnames(i).name,path,LineNo, ...
                channelColors,axesNames,darkBackgroundFlag,guiInput,secondsPerFrame,normalization,legendLocation, micronsPerPixel, ...
                xMinStepMax, ...
                yMinStepMax, ...
                num, ...
                imageFileName,...
                velocityStartStop);
        end
    end
end
%check for subdirectories
allnames=dir(path);
allnames(~[allnames.isdir]) = [];  %remove non-directories
tf = ismember( {allnames.name}, {'.', '..'});
allnames(tf) = [];  %remove current and parent directory.
for i=1:size(allnames,1)
    OutlinerFolderLoader(fullfile(path,allnames(i).name), ...
        channelColors,axesNames,darkBackgroundFlag,guiInput,secondsPerFrame,normalization,legendLocation, micronsPerPixel, ...
        xMinStepMax, ...
        yMinStepMax, ...
        num, ...
        imageFileName,...
        velocityStartStop);
end
end

function LineNo=SphinctalyzerMP(filename,path,LineNo, ...
    channelColors,axesNames,darkBackgroundFlag,guiInput,secondsPerFrame,normalization,legendLocation, micronsPerPixel, ...
    xMinStepMax, ...
    yMinStepMax, ...
    num, ...
    imageFileName,...
    velocityStartStop)
frmrate=2; %this is the framerate in frames/second
PreWoundFrame=1;  %Choose 1 to use a pre-wound frame for background removal, 2 for best guess.
normalizationframe= 1; %if choosing to use pre-wound frame for normalization, select frame
InterpolationFrames = 1; %1 for uninterpolated, larger integers for smoother output

SpecifyRange=0; %0 to use full scanned range, 1 to use range from next line
CropRange=3:5; %Format is first frame:last frame.  Frames not scanned in loaded data will not be used.

TimeZeroFrame=1; %This frame will be used as timepoint zero
TimeUnit='seconds'; %This string will be used as the time label

SelectChannels=0; %0 to use all channels, 1 to use only select channels
ChannelsOn=[ 1 2 ]; %Channels listed will be used

if guiInput == 1
    if micronsPerPixel == 1
        xmin = xMinStepMax(1);
        xstep = xMinStepMax(2);
        xmax = xMinStepMax(3);
    else
        xmin = round(xMinStepMax(1) / micronsPerPixel);
        xmax = round(xMinStepMax(3) / micronsPerPixel);
    end
    ColorMat = channelColors;
    yAxisTitle = axesNames{2};
    xAxisTitle = axesNames{1};
    TimePerFrame = secondsPerFrame; %This is the time between frames during imaging (second/frame)
else
    xmin=-150; % minimum x axis, in pixels
    xmax=0;% maximum x axis, in pixels
    ColorMat={[1 0 0],[0 .6 0],[0 0 1]}; %These are the color strings for each channel
    yAxisTitle = 'Normalized Gray Value';
    if micronsPerPixel == 1
        xAxisTitle = 'Distance (pixels) from wound center';
    else
        xAxisTitle = 'Position (Microns) relative to wound center';
    end
    TimePerFrame = 10; %This is the time between frames during imaging (second/frame)
    normalization=1;  %Choose 1 for each color normalized to itself, 2 for percent change, 3 for no normalization, 4 for all frames norm to 100%
    switch normalization
        case 1
            yAxisTitle = 'Normalized Gray Value';
        case 2
            yAxisTitle = 'Fold over Background';
        case 3
            yAxisTitle = 'Gray Value';
        case 4
            yAxisTitle = 'Normalized Gray Value';
    end
end
TypeString='Smooth'; %'Mean' 'Median' or 'Smooth'

matResults = load([path,'/',filename],'SphinctalyzerOutputs','InputCells');
SphinctalyzerOutputs = matResults.SphinctalyzerOutputs;
InputCells =  matResults.InputCells;

Range=find([SphinctalyzerOutputs.InRange]==1)';
if SpecifyRange==1
    Range=Range(ismember(Range, CropRange));
end
if SelectChannels==0
       ChannelStrings=InputCells(:,1);
else
    try
        ChannelStrings=InputCells(ChannelsOn,1);
    catch exception
        ChannelStrings=InputCells(:,1);
        display('Selected Channels do not exist, plotting all channels')
    end
end
InterpolationX=InterpolationFrames;
%% Normalization Calculation
if normalization == 1;
    ylims=[-.1,1.1];
    yticks=[0:.2:1];
    ystring=yAxisTitle;
    if PreWoundFrame == 1;
        for i=1:size(ChannelStrings,1)
            IntensityVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
            XVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=max(IntensityVals(XVals<=30&XVals>=-30));
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=mean(mean(double(SphinctalyzerOutputs(normalizationframe).(matlab.lang.makeValidName([ChannelStrings{i},'Data'])))));
        end
    elseif PreWoundFrame == 2;
        for i=1:size(ChannelStrings,1)
            IntensityVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
            XVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=max(IntensityVals(XVals<=30&XVals>=-30));
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=median(IntensityVals);
        end
    end
elseif normalization == 2;
    ylims=[-1 6];
    yticks=[0:1:5];
    ystring=yAxisTitle;
    if PreWoundFrame == 1;
        for i=1:size(ChannelStrings,1)
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=mean(mean(double(SphinctalyzerOutputs(normalizationframe).(matlab.lang.makeValidName([ChannelStrings{i},'Data'])))));
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=2*FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']));
        end
        
    elseif PreWoundFrame == 2;
        for i=1:size(ChannelStrings,1)
            IntensityVals=SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']));
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=median(IntensityVals);
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=2*FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']));
        end
    end
elseif normalization == 3;
    for i=1:size(ChannelStrings,1)
        FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=0;
        FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=1;
    end
    
    ylims=[0 4100];
    yticks=[0:500:4000];
    ystring=yAxisTitle;
elseif normalization == 4
    ylims=[-.1,1.1];
    yticks=[0:.2:1];
    ystring=yAxisTitle;
    if PreWoundFrame == 1;
        for i=1:size(ChannelStrings,1)
            for j=min(Range):max(Range)
                IntensityVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
                XVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
                Max=max(IntensityVals(XVals<=30&XVals>=-30));
                Med=median(median(double([SphinctalyzerOutputs(normalizationframe).(matlab.lang.makeValidName([ChannelStrings{i},'Data']))])));
                [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))]=(IntensityVals-Med)/(Max-Med)
            end
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=1;
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=0;
        end
    elseif PreWoundFrame == 2;
        for i=1:size(ChannelStrings,1)
            for j=min(Range):max(Range)
                IntensityVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
                XVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
                Max=max(IntensityVals(XVals<=30&XVals>=-30));
                Med=median(median(double(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'Data'])))));
                [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))]=(IntensityVals-Med)/(Max-Med)
            end
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=1;
            FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=0;
        end
    end
end

%% Centroid Calculation
if strcmp(SphinctalyzerOutputs(1).RefChannel{:},'Self')
    for i=1:size(ChannelStrings,1)
        VariableNames(i).CentroidOutline={SphinctalyzerOutputs.(matlab.lang.makeValidName([ChannelStrings{i,:},'Outline']))};
    end
    centroids=CentroidfromOutline(VariableNames.CentroidOutline);
    for i = min(Range):max(Range)
        for j = 1:size(ChannelStrings,1)
        Shifts(i).(matlab.lang.makeValidName([ChannelStrings{j},'Shifts']))=OutlineDistfromCentroid(centroids(i,:), {SphinctalyzerOutputs(i).(matlab.lang.makeValidName([ChannelStrings{j},'Outline']))});
        end
    end
else
    centroids=CentroidfromOutline({SphinctalyzerOutputs.(matlab.lang.makeValidName([SphinctalyzerOutputs(1).RefChannel{:}, 'Outline']))}) ;
        for i = min(Range):max(Range)
        for j = 1:size(ChannelStrings,1)
        Shifts(i).(matlab.lang.makeValidName([ChannelStrings{j},'Shifts']))=OutlineDistfromCentroid(centroids(i,:), {SphinctalyzerOutputs(i).(matlab.lang.makeValidName([SphinctalyzerOutputs(1).RefChannel{:},'Outline']))});
        end
    end
end

%% Iteration over data
xprime=[-350:1:350];
yprime=Range;
[xprimegrid,yprimegrid]=meshgrid(xprime,yprime);
x=[xmin:(1/InterpolationX):xmax];
y=[min(Range):1/InterpolationFrames:max(Range)];
[X2,Y2]=meshgrid(xprime,y);
[Xr,Yr]=meshgrid(x,y);
%initialize the peak parameters
channelsNo = size(ChannelStrings,1);
frameInrange = length(min(Range):max(Range));
Peaks=nan(channelsNo,frameInrange);
Halfwidths=nan(channelsNo,frameInrange);
AUCs=nan(channelsNo,frameInrange);
PeakLocs=nan(channelsNo,frameInrange);
for i=1:size(ChannelStrings,1)
    zprimegrid=NaN(size(xprimegrid));
    for j=min(Range):max(Range)
        XVals=double(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances'])));
        Intensities=(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))-FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med'])))/(FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))-FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med'])));
        try
            [PeakIntensity,HalfWidth, PeakAUC, PeakLocation]=IntensityIntegrator(Intensities, XVals);

        Peaks(i,j)=PeakIntensity;
        Halfwidths(i,j)=HalfWidth*micronsPerPixel;
        AUCs(i,j)=PeakAUC*micronsPerPixel;
      %  if strcmp(SphinctalyzerOutputs(1).RefChannel{:},'Self')
        PeakLocs(i,j)=(PeakLocation-Shifts(j).(matlab.lang.makeValidName([ChannelStrings{i},'Shifts'])))*micronsPerPixel;
       % else
       % end

        catch peakError
            fprintf("peak location calculation error: %s \n", peakError.message)
            Peaks(i,j) = nan;
            PeakLocs(i,j) = nan;
            Halfwidths(i,j) = nan;
            AUCs(i,j) = nan;
            PeakLocs(i,j) = nan;
            fprintf('peak location, half width, AUCs,  are set to NaN for frame %d of Channel %d \n', j,i)
        end
        zprimegrid(j-min(Range)+1, :)=interp1(XVals,Intensities,xprime);
    end
    Z2r=interp2(xprimegrid,yprimegrid,zprimegrid, X2,Y2);
    Zr=zeros(size(Xr));
    ShiftInterp=interp1(Range,[Shifts.(matlab.lang.makeValidName([ChannelStrings{i},'Shifts']))],y);
    for k=1:length(y)
        XVals=xprime-ShiftInterp(k);
        Intensities=Z2r(k,:);
        Zr(k, :)=interp1(XVals,Intensities,x);
    end
    IntensityOut.(matlab.lang.makeValidName(ChannelStrings{i}))=Zr;
end
savepath=[path,'/'];
savename=strrep(filename,'sphinc','Scan movie');
savename = savename(1:end-4);
%% ADD NUMBER TO NAME
if guiInput == 1
    savename=strrep(filename,'sphinc',strcat(imageFileName,'_scan_movie'));
    savename = savename(1:end-4);
    savename = strcat(savename, '_',num2str(num));
    %add corresponding excel file name
    excelSavename = strcat('Results','_',num2str(num),'.xlsx');
else
    excelSavename = 'Results_1.xlsx';
end


writerObj = VideoWriter(fullfile(savepath,strcat([savename,'.avi'])));
set(writerObj,'FrameRate',frmrate*InterpolationFrames);
open(writerObj);
gcf1 = figure;

for i= 1:size(Zr,1)
    hold off
    for j = 1:size(ChannelStrings,1)
    eval(['plot(x,IntensityOut.',(matlab.lang.makeValidName(ChannelStrings{j})),'(i,:),''color'', [',num2str(ColorMat{j}),'] ,''linewidth'',4)'])%./(max(ImageOutputs.valyred{i})-median(ImageOutputs.valyred{i})),'r','LineWidth',4);%./max(valval1{i})
    hold on
    end
    set(gcf1,'Position',[1 1 1000 500]);
    if guiInput == 1
        xlim(gca,[xmin, xmax])
        ylim(gca,[yMinStepMax(1),yMinStepMax(3)])
        set(gca,'YTick',yMinStepMax(1):yMinStepMax(2):yMinStepMax(3))
        set(gca,'XTick',xmin:round(xMinStepMax(2)/micronsPerPixel):xmax)
        set(gca,'XTickLabel',xMinStepMax(1):xMinStepMax(2):xMinStepMax(3))
        set(gca,'FontSize',24)
        set(gca,'FontName','Arial','FontWeight','bold')
        xlabel(sprintf('%s \nTime = %.1f %s', xAxisTitle,(((min(Range)-TimeZeroFrame)+(i-1)/InterpolationFrames)*TimePerFrame),TimeUnit))
    else
        xlim(gca,[-150 0]);
        ylim(gca,ylims);
        set(gca,'YTick',yticks)
        set(gca,'YTickLabel',yticks)
        set(gca,'FontSize',24)
        set(gca,'FontName','Arial','FontWeight','bold')
        xlabel(sprintf('%s \nTime = %.1f %s', xAxisTitle,(((min(Range)-TimeZeroFrame)+(i-1)/InterpolationFrames)*TimePerFrame),TimeUnit))
        if micronsPerPixel ~= 1
            set(gca,'XTickLabel',LabelConverter((cellfun(@str2num, get(gca,'XTickLabel')).*micronsPerPixel)))
        end
    end
    lgd = legend(ChannelStrings,'Location',legendLocation,'FontSize',24,'FontName','Arial');
    set(gcf1, 'Color', 'w')
    set(gca, 'Color', 'w')
    ylabel(ystring)
    if guiInput == 1
        if darkBackgroundFlag == 1
            set(gcf1, 'Color', 'k')
            set(gca, 'Color', 'k')
            set(gca, 'XColor', [1 1 1])
            set(gca, 'YColor', [1 1 1])
            lgd.Color = [0 0 0];
            lgd.TextColor = [1 1 1];
        end
    end
    
    %annotation(gcf,'textbox',...
    %[0.789 .826 .1125 .088],...
    %'String',{'Wound'},...
    %'FitBoxToText','off','FontName','Arial','FontSize',24,'HorizontalAlignment','Center','BackgroundColor',[1 1 1]);
    pause(.01)
    frame=getframe(gcf1);
    % for debugging, if figure is shown in different diplays with different
    % resolution, the frame size will probably change, and will casue error
    % fprintf('%d: frame size-%dx%d \n',i,size(frame.cdata,1),size(frame.cdata,2)) 
    writeVideo(writerObj,frame);
end
%MovieWriter
close(writerObj);
% movefile([savename,'.avi'],savepath);
close(gcf1)
%save parameters to the excel file
parameters_post = cell(13,4);
parameters_post{1,1} = 'Channel Colors'; 
nColors = length(channelColors);
for i = 1:nColors
    parameters_post{1,i+1} = mat2str(channelColors{i});
end
parameters_post{2,1} = 'Axes Names'; 
nAxesNames = length(axesNames);
for i = 1:nAxesNames
    parameters_post{2,i+1} = axesNames{i};
end
parameters_post{3,1} = 'DarkBackgroundFlag'; parameters_post{3,2} = darkBackgroundFlag;
parameters_post{4,1} = 'SecondsPerFrame'; parameters_post{4,2} = secondsPerFrame;
parameters_post{5,1} = 'Normalization'; parameters_post{5,2} = normalization;
parameters_post{6,1} = 'Legend Location'; parameters_post{6,2} = legendLocation;
parameters_post{7,1} = 'MicronsPerPixel'; parameters_post{7,2} = micronsPerPixel;
parameters_post{8,1} = 'xMinStepMax'; parameters_post{8,2} = mat2str(xMinStepMax);
parameters_post{9,1} = 'yMinStepMax'; parameters_post{9,2} = mat2str(yMinStepMax);
parameters_post{10,1} = 'File Index'; parameters_post{10,2} = num; 
parameters_post{11,1} = 'Image Filename'; parameters_post{11,2} = imageFileName;
parameters_post{12,1} = 'Results Folder'; parameters_post{12,2} = savepath;
parameters_post{13,1} = 'velocityStartStop';parameters_post{13,2} = mat2str(velocityStartStop);
writecell(parameters_post,[savepath, excelSavename],'Sheet','parameters','Range','A1');

%% add a sheet of "Closing Velocity and Location" 
% calculate wound closing velocity
% peakLocations = xlsSheets{2};
peakLocations = PeakLocs;
timePerFrame = secondsPerFrame;
closing_checkpoint_values = [2/3 1/2 1/3];   % 2/3 closing
closing_checkpoint_strings = {'2/3' '1/2' '1/3'};
nChannels = length(ChannelStrings);
closingVelocityLocation_value = nan(6,nChannels);
closingVelocityLocation_label = {'Velocity start frame';...
    'Velocity end frame';...
    'Closing velocity (um/second)';...
    sprintf('frame at %s closing position',closing_checkpoint_strings{1});...
    sprintf('frame at %s closing position',closing_checkpoint_strings{2});...
    sprintf('frame at %s closing position',closing_checkpoint_strings{3})};
% add the options of using different velocity Start and Stop points
if nChannels>1 & size(velocityStartStop,1)==1
    velocityStartStop_channel = repmat(velocityStartStop,nChannels,1);
    %debugging
    velocityStartStop_channel(2,1) =  velocityStartStop_channel(2,1)+4;
    velocityStartStop_channel(2,2) =  velocityStartStop_channel(2,2)-3;  
else
    velocityStartStop_channel = velocityStartStop;
end

for b = 1:nChannels
    woundClosingVelocity = ((peakLocations(b, velocityStartStop_channel(b,2)) - peakLocations(b, velocityStartStop_channel(b,1))) / ((velocityStartStop_channel(b,2) - velocityStartStop_channel(b,1)) * timePerFrame)); %* obj.micronsPerPixel;
    closingVelocityLocation_value(1,b) = velocityStartStop_channel(b,1);
    closingVelocityLocation_value(2,b) = velocityStartStop_channel(b,2);
    closingVelocityLocation_value(3,b) = woundClosingVelocity;
end
% calculate the nearest frame index corresponding to 2/3, 1/2, 1/3
% of peak location value
location_checkpoint_values = closing_checkpoint_values;
location_checkpoint_strings = closing_checkpoint_strings;

try
    for b = 1:nChannels
        location_start = velocityStartStop_channel(b,1);
        location_end = velocityStartStop_channel(b,2);
        peakLocation_start = peakLocations(b, location_start);  % distance to the center
        locations_inRange = peakLocations(b, location_start:location_end);
        averageDistance = abs((peakLocations(b,location_start)-peakLocations(b,location_end))/(location_end-location_start));
        %peakLocation_end = peakLocations(b, obj.velocityStartStop_channel(b,2));
        for cp = 1:length(location_checkpoint_values)
            location_checkpoint = location_checkpoint_values(cp)*peakLocation_start;
            distances2checkpoint = abs(locations_inRange - location_checkpoint);
            minimum_distance = min(distances2checkpoint);
            if  minimum_distance> averageDistance
                nearestFrame_value = nan;
                fprintf(['Channel %d: No frame found near to the %s (%3.2f um) of closing start location.\n ' ...
                    '  Minimum distance( %3.2f um) is bigger than the averarge distance between adjacent frames(%3.2f um) \n'],...
                    b, location_checkpoint_strings{cp}, location_checkpoint, minimum_distance,averageDistance)
            else
                nearestFrame_index = find(distances2checkpoint== minimum_distance);
                nearestFrame_value = location_start+nearestFrame_index-1;
                fprintf(['Channel %d: nearest frame around %s (%3.2f) of closing start location (%3.2f) is:%d. \n ' ...
                    '  The distance between this frame and this closing location is :%3.2f um,\n    equal or smaller than' ...
                    'the average distance between adjacent frames %3.2f um \n'],...
                    b, location_checkpoint_strings{cp},location_checkpoint,peakLocation_start,nearestFrame_value,minimum_distance,averageDistance);
            end
            closingVelocityLocation_value(cp+3,b) = nearestFrame_value;
        end
    end
catch closingLocationEXP
    fprintf('%s closing location of channel %d is not found, \n error message:%s \n',...
        closing_checkpoint_strings{cp},b, closingLocationEXP.message)
end

%save results to the excel file
writematrix(Peaks,[savepath, excelSavename],'Sheet','Peak Intensity','Range',['C' num2str(LineNo)]);
writematrix(PeakLocs,[savepath, excelSavename],'Sheet','Peak Locations','Range',['C' num2str(LineNo)]);
writematrix(Halfwidths,[savepath, excelSavename],'Sheet','Halfwidths','Range',['C' num2str(LineNo)]);
writematrix(AUCs,[savepath, excelSavename],'Sheet','AUCs','Range',['C' num2str(LineNo)]);
writematrix(Peaks,[savepath, excelSavename],'Sheet','Percent Above Background','Range',['C' num2str(LineNo)]);
writematrix(closingVelocityLocation_value,[savepath, excelSavename],'Sheet','Closing Velocity and Location','Range',['C' num2str(LineNo)]);


% add frame index in the first row of the output folder
frameIndexes = 1:length(Peaks);
writematrix(frameIndexes,[savepath, excelSavename],'Sheet','Peak Intensity','Range',['C' num2str(LineNo-1)]);
writematrix(frameIndexes,[savepath, excelSavename],'Sheet','Peak Locations','Range',['C' num2str(LineNo-1)]);
writematrix(frameIndexes,[savepath, excelSavename],'Sheet','Halfwidths','Range',['C' num2str(LineNo-1)]);
writematrix(frameIndexes,[savepath, excelSavename],'Sheet','AUCs','Range',['C' num2str(LineNo-1)]);
writematrix(frameIndexes,[savepath, excelSavename],'Sheet','Percent Above Background','Range',['C' num2str(LineNo-1)]);

% %% Normalization Calculation
% if normalization == 1
%     ylims=[-.1,1.1];
%     yticks=[0:.2:1];
%     ystring='Normalized gray value ';
%     if PreWoundFrame == 1
%         for i=1:size(ChannelStrings,1)
%             IntensityVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
%             XVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=max(IntensityVals(XVals<=30&XVals>=-30));
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=mean(mean(double(SphinctalyzerOutputs(normalizationframe).(matlab.lang.makeValidName([ChannelStrings{i},'Data'])))));
%         end
%     elseif PreWoundFrame == 2
%         for i=1:size(ChannelStrings,1)
%             IntensityVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
%             XVals=[SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=max(IntensityVals(XVals<=30&XVals>=-30));
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=median(IntensityVals);
%         end
%     end
% elseif normalization == 2
%     ylims=[-1 6];
%     yticks=[0:1:5];
%     ystring='Fold above background';
%     if PreWoundFrame == 1
%         for i=1:size(ChannelStrings,1)
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=mean(mean(double(SphinctalyzerOutputs(normalizationframe).(matlab.lang.makeValidName([ChannelStrings{i},'Data'])))));
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=2*FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']));
%         end
% 
%     elseif PreWoundFrame == 2
%         for i=1:size(ChannelStrings,1)
%             IntensityVals=SphinctalyzerOutputs(Range).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']));
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=median(IntensityVals);
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=2*FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']));
%         end
%     end
% elseif normalization == 3
%     for i=1:size(ChannelStrings,1)
%         FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=0;
%         FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=1;
%     end
% 
%     ylims=[0 4100];
%     yticks=[0:500:4000];
%     ystring='Gray Value';
% elseif normalization == 4
%     ylims=[-.1,1.1];
%     yticks=[0:.2:1];
%     ystring='Normalized gray value ';
%     if PreWoundFrame == 1
%         for i=1:size(ChannelStrings,1)
%             for j=min(Range):max(Range)
%                 IntensityVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
%                 XVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
%                 Max=max(IntensityVals(XVals<=30&XVals>=-30));
%                 Med=median(median(double([SphinctalyzerOutputs(normalizationframe).(matlab.lang.makeValidName([ChannelStrings{i},'Data']))])));
%                 [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))]=(IntensityVals-Med)/(Max-Med)
%             end
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=1;
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=0;
%         end
%     elseif PreWoundFrame == 2
%         for i=1:size(ChannelStrings,1)
%             for j=min(Range):max(Range)
%                 IntensityVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))];
%                 XVals=[SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances']))];
%                 Max=max(IntensityVals(XVals<=30&XVals>=-30));
%                 Med=median(median(double(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'Data'])))));
%                 [SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))]=(IntensityVals-Med)/(Max-Med)
%             end
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))=1;
%             FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med']))=0;
%         end
%     end
% end
% 
% %% Centroid Calculation
% if strcmp(SphinctalyzerOutputs(1).RefChannel{:},'Self')
%     for i=1:size(ChannelStrings,1)
%         VariableNames(i).CentroidOutline={SphinctalyzerOutputs.(matlab.lang.makeValidName([ChannelStrings{i,:},'Outline']))};
%     end
%     centroids=CentroidfromOutline(VariableNames.CentroidOutline);
%     for i = min(Range):max(Range)
%         for j = 1:size(ChannelStrings,1)
%         Shifts(i).(matlab.lang.makeValidName([ChannelStrings{j},'Shifts']))=OutlineDistfromCentroid(centroids(i,:), {SphinctalyzerOutputs(i).(matlab.lang.makeValidName([ChannelStrings{j},'Outline']))});
%         end
%     end
% else
%     centroids=CentroidfromOutline({SphinctalyzerOutputs.(matlab.lang.makeValidName([SphinctalyzerOutputs(1).RefChannel{:}, 'Outline']))}) ;
%         for i = min(Range):max(Range)
%         for j = 1:size(ChannelStrings,1)
%         Shifts(i).(matlab.lang.makeValidName([ChannelStrings{j},'Shifts']))=OutlineDistfromCentroid(centroids(i,:), {SphinctalyzerOutputs(i).(matlab.lang.makeValidName([SphinctalyzerOutputs(1).RefChannel{:},'Outline']))});
%         end
%     end
% end
% 
% %% Iteration over data
% xprime=[-350:1:350];
% yprime=Range;
% [xprimegrid,yprimegrid]=meshgrid(xprime,yprime);
% x=[xmin:(1/InterpolationX):xmax];
% y=[min(Range):1/InterpolationFrames:max(Range)];
% [X2,Y2]=meshgrid(xprime,y);
% [Xr,Yr]=meshgrid(x,y);
% for i=1:size(ChannelStrings,1)
%     zprimegrid=NaN(size(xprimegrid));
%     for j=min(Range):max(Range)
%         XVals=double(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances'])));
%         Intensities=(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))-FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med'])))/(FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))-FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med'])));
%         try
%             [PeakIntensity,HalfWidth, PeakAUC, PeakLocation]=IntensityIntegrator(Intensities, XVals);
% 
%         Peaks(i,j)=PeakIntensity;
%         Halfwidths(i,j)=HalfWidth*micronsPerPixel;
%         AUCs(i,j)=PeakAUC*micronsPerPixel;
%       %  if strcmp(SphinctalyzerOutputs(1).RefChannel{:},'Self')
%         PeakLocs(i,j)=(PeakLocation-Shifts(j).(matlab.lang.makeValidName([ChannelStrings{i},'Shifts'])))*micronsPerPixel;
%        % else
%        % end
%                 catch
%             i
%             j
%         end
%         zprimegrid(j-min(Range)+1, :)=interp1(XVals,Intensities,xprime);
%     end
%     Z2r=interp2(xprimegrid,yprimegrid,zprimegrid, X2,Y2);
%     Zr=zeros(size(Xr));
%     ShiftInterp=interp1(Range,[Shifts.(matlab.lang.makeValidName([ChannelStrings{i},'Shifts']))],y);
%     for k=1:length(y)
%         XVals=xprime-ShiftInterp(k);
%         Intensities=Z2r(k,:);
%         Zr(k, :)=interp1(XVals,Intensities,x);
%     end
%     IntensityOut.(matlab.lang.makeValidName(ChannelStrings{i}))=Zr;
% end

% writematrix(Peaks,[savepath, excelSavename],'Sheet','Percent Above Background','Range',['C' num2str(LineNo)]);


writecell(ChannelStrings,[savepath, excelSavename],'Sheet','Percent Above Background','Range',['B' num2str(LineNo)]);
writecell(ChannelStrings,[savepath, excelSavename],'Sheet','AUCs','Range',['B' num2str(LineNo)]);
writecell(ChannelStrings,[savepath, excelSavename],'Sheet','Halfwidths','Range',['B' num2str(LineNo)]);
writecell(ChannelStrings,[savepath, excelSavename],'Sheet','Peak Intensity','Range',['B' num2str(LineNo)]);
writecell(ChannelStrings,[savepath, excelSavename],'Sheet','Peak Locations','Range',['B' num2str(LineNo)]);
writecell(ChannelStrings',[savepath, excelSavename],'Sheet','Closing Velocity and Location','Range',['C' num2str(LineNo-1)]);
writecell(closingVelocityLocation_label,[savepath, excelSavename],'Sheet','Closing Velocity and Location','Range',['B' num2str(LineNo)]);


%add frame Name
frameLabel = {'Frame Index'};
writecell(frameLabel,[savepath, excelSavename],'Sheet','Percent Above Background','Range',['B' num2str(LineNo-1)]);
writecell(frameLabel,[savepath, excelSavename],'Sheet','AUCs','Range',['B' num2str(LineNo-1)]);
writecell(frameLabel,[savepath, excelSavename],'Sheet','Halfwidths','Range',['B' num2str(LineNo-1)]);
writecell(frameLabel,[savepath, excelSavename],'Sheet','Peak Intensity','Range',['B' num2str(LineNo-1)]);
writecell(frameLabel,[savepath, excelSavename],'Sheet','Peak Locations','Range',['B' num2str(LineNo-1)]);


savenamecrop=savename(1:findstr(savename,'scan_movie')-2); % extract the image name
writecell({savenamecrop},[savepath, excelSavename],'Sheet','Percent Above Background','Range',['A' num2str(LineNo)]);
writecell({savenamecrop},[savepath, excelSavename],'Sheet','AUCs','Range',['A' num2str(LineNo)]);
writecell({savenamecrop},[savepath, excelSavename],'Sheet','Halfwidths','Range',['A' num2str(LineNo)]);
writecell({savenamecrop},[savepath, excelSavename],'Sheet','Peak Intensity','Range',['A' num2str(LineNo)]);
writecell({savenamecrop},[savepath, excelSavename],'Sheet','Peak Locations','Range',['A' num2str(LineNo)]);
writecell({savenamecrop},[savepath, excelSavename],'Sheet','Closing Velocity and Location','Range',['A' num2str(LineNo)]);



LineNo=LineNo+size(ChannelStrings,1);
end
