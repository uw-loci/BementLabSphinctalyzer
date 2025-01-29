function [PeakIntensity,HalfWidth, PeakAUC, PeakLocationX]=IntensityIntegrator(Intensities, XVals)
IntensitiesOld=Intensities;
Intensities=Intensities-min(IntensitiesOld);
Marker=Intensities.*(XVals==0);
NewIM=imreconstruct(Marker, Intensities);
PeakLogic=NewIM==max(NewIM);
PeakLocation=find(Intensities==max(Intensities.*PeakLogic));
PeakLocationX=XVals(PeakLocation);
PeakIntensity=Intensities(PeakLocation)+min(IntensitiesOld);
NewIM2=imreconstruct((Intensities==max(Intensities.*PeakLogic)).*Intensities,Intensities);
IMDiff=NewIM2-Intensities;
IMDifftrunc=IMDiff(PeakLocation+12:end);
FirstDrop=PeakLocation+12+find(IMDifftrunc<0,1)-2;
if isempty(FirstDrop)
    FirstDrop=length(Intensities);
end
IntensityTrunc=IntensitiesOld(1:FirstDrop);
XValsTrunc=XVals(1:FirstDrop);
IntensityLower=IntensityTrunc(1:PeakLocation);
XLower=XValsTrunc(1:PeakLocation);
IntensityUpper=IntensityTrunc(PeakLocation:end);
XUpper=XValsTrunc(PeakLocation:end);
Xzerolower=((max(XLower(IntensityLower<=0))));
Xhalflower=(max(XLower(IntensityLower<=PeakIntensity/2)));
Xzeroupper=(min(XUpper(IntensityUpper<=0)));
Xhalfupper=(min(XUpper(IntensityUpper<=PeakIntensity/2)));
%In future, should interpolate to get more accurate half width and AUC
HalfWidth=Xhalfupper-Xhalflower-1;% estimated
if isempty(Xzerolower)
    Xzerolower=min(XLower);
else Xzerolower=Xzerolower+1;
end
if isempty(Xzeroupper)
    Xzeroupper=max(XUpper);
else
    Xzeroupper=Xzeroupper-1;
end
TrimPeak=IntensityTrunc(find(XValsTrunc==Xzerolower):find(XValsTrunc==Xzeroupper));
PeakAUC=trapz(TrimPeak);
if isempty(HalfWidth)
    HalfWidth=NaN;
end
%debugging starts here
if isnan(HalfWidth)
    fig1 = figure, plot(XVals,NewIM,'k<')
    hold on, plot(XVals,Intensities,'bo')
    hold on, plot(XVals,NewIM2,'m*')

    fprintf('Peak Location = %d \n, XVals position = %d \n Max intensity position = %d \n',...
        PeakLocation, find(XVals==0),find(Intensities == max(Intensities)))
    xlim([-20 20])
    close(fig1)
end

%debugging ends here