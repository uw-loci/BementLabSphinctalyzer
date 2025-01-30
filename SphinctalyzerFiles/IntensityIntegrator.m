function [PeakIntensity,HalfWidth, PeakAUC, PeakLocationX]=IntensityIntegrator(Intensities, XVals)
IntensitiesOld=Intensities;
Intensities=Intensities-min(IntensitiesOld);
% Marker=Intensities.*(XVals==0);
Marker=Intensities.*(Intensities==max(Intensities));  %update on 01/30/2025: mark the maximum intensity position instead of XVals==0
NewIM=imreconstruct(Marker, Intensities);
PeakLogic=NewIM==max(NewIM);
PeakLocation=find(Intensities==max(Intensities.*PeakLogic));
if length(PeakLocation)>1
    fprintf('%d peak points were found for this frame, only the first one is kept \n',length(PeakLocation))
    PeakLocation= PeakLocation(1);
end
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
    fig1 = figure('Position',[1800 900 600 400]), plot(XVals,NewIM,'k<')
    hold on, plot(XVals,Intensities,'bo')
    hold on, plot(XVals,NewIM2,'m*')
    hold on, plot(0,Intensities(find(XVals==0)),'rd')
    fprintf('Check calculation  \n Peak Location = %d \n, XVals position = %d \n Max intensity position = %d \n',...
        PeakLocation, find(XVals==0),find(Intensities == max(Intensities)))
    disp('Half width is not obtained, the peak calculation might be incorrect for this frame')
    xlim([-50 50])
    legend({'NewIM','Intensities','NewIM2','X0'},'Location','northwest')
    pause(3) 
    xlim([XVals(PeakLocation)-10,XVals(PeakLocation)+10])
    pause(3)
    close(fig1)
end
%debugging ends here