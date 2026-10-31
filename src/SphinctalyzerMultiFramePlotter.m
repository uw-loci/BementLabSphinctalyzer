function SphinctalyzerMultiFramePlotter
%% edit this area
frmrate=1; %this is the framerate in frames/second
normalization=2;  %Choose 1 for each color normalized to itself, 2 for percent change, 3 for no normalization, 4 for all frames norm to 100%
PreWoundFrame=1;  %Choose 1 to use a pre-wound frame for background removal, 2 for best guess.
normalizationframe= 1; %if choosing to use pre-wound frame for normalization, select frame
InterpolationFrames = 1; %1 for uninterpolated, larger integers for smoother output
SpecifyRange=1; %0 to use full scanned range, 1 to use range from next line
CropRange=9:10; %Format is first frame:last frame.  Frames not scanned in loaded data will not be used.

MicronsPerPixel=.192;
TimeZeroFrame=1;
TimePerFrame=10;
TimeUnit='seconds';
SelectChannels=1; %0 to use all channels, 1 to use only select channels
ChannelsOn=[ 1 ]; %Channels listed will be used

xmin=-150; % in pixels
xmax=-15;%in pixels
ColorMat={[1 0 0],[0 .6 0],[0 0 1]};
TypeString='Smooth'; %'Mean' 'Median' or 'Smooth'

%% No edits below this point
[filename, path]=uigetfile({'*.mat'},'Point me to your sphinctalyzer outputs');
load([path,filename]);

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
    ystring='Normalized gray value ';
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
    ystring='Fold above background';
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
    ystring='Gray Value';
elseif normalization == 4
    ylims=[-.1,1.1];
    yticks=[0:.2:1];
    ystring='Normalized gray value ';
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
for i=1:size(ChannelStrings,1)
    zprimegrid=NaN(size(xprimegrid));
    for j=min(Range):max(Range)
        XVals=double(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},'XDistances'])));
        Intensities=(SphinctalyzerOutputs(j).(matlab.lang.makeValidName([ChannelStrings{i},TypeString,'Intensities']))-FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med'])))/(FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Max']))-FuncData.(matlab.lang.makeValidName([ChannelStrings{i},'Med'])));
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

for i= 1:size(Zr,1)
    hold off
    figure
    for j = 1:size(ChannelStrings,1)
    eval(['plot(x,IntensityOut.',(matlab.lang.makeValidName(ChannelStrings{j})),'(i,:),''color'', [',num2str(ColorMat{j}),'] ,''linewidth'',4)'])%./(max(ImageOutputs.valyred{i})-median(ImageOutputs.valyred{i})),'r','LineWidth',4);%./max(valval1{i})
    hold on
    end
    set(gcf,'Position',[1 1 1000 500]);
    xlim(gca,[-150 0]);
    ylim(gca,ylims);
    set(gca,'YTick',yticks)
    set(gca,'YTickLabel',yticks)
    set(gca,'FontSize',24)
    set(gca,'FontName','Arial','FontWeight','bold')
    if MicronsPerPixel==1
    xlabel(sprintf('Distance (pixels) from wound center\nTime = %.1f %s',(((min(Range)-TimeZeroFrame)+(i-1)/InterpolationFrames)*TimePerFrame),TimeUnit))
    else
        xlabel(sprintf('Position relative to wound center (\\mum)\nTime = %.1f %s', (((min(Range)-TimeZeroFrame)+(i-1)/InterpolationFrames)*TimePerFrame),TimeUnit))
        set(gca,'XTickLabel',LabelConverter((cellfun(@str2num, get(gca,'XTickLabel')).*MicronsPerPixel)))
    end
    ylabel(ystring)
    legend(ChannelStrings,'Location','NorthWest','FontSize',24,'FontName','Arial');
    %annotation(gcf,'textbox',...
    %[0.789 .826 .1125 .088],...
    %'String',{'Wound'},...
    %'FitBoxToText','off','FontName','Arial','FontSize',24,'HorizontalAlignment','Center','BackgroundColor',[1 1 1]);
end
