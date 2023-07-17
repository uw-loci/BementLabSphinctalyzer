function [bw]=PolarSmooth(qq,SmoothNo)
cent=regionprops(imfill(qq,'holes'),'Centroid');
roundCent=round(cent.Centroid);
py=roundCent(2);
xs=find(qq(round(cent.Centroid(2)),:)==1);
px=xs(end);
B=bwtraceboundary(imfill(qq,'holes'),[py,px],'N',8,Inf,'clockwise');
Coords=fliplr(B(1:end-1,:));
CoordsZero=Coords-repmat(roundCent,size(Coords,1),1);
[theta,rho]=cart2pol(CoordsZero(:,1),CoordsZero(:,2));
theta=wrapTo2Pi(theta);
thetaExtra=[theta(end-SmoothNo+1:end)-2*pi;theta;theta(1:SmoothNo)+2*pi];
rhoExtra=[rho(end-SmoothNo+1:end);rho;rho(1:SmoothNo)];
thetaSmooth=smooth(thetaExtra,SmoothNo);
rhoSmooth=smooth(rhoExtra, SmoothNo);
[Xnew,Ynew]=pol2cart(thetaSmooth(SmoothNo+1:end-SmoothNo),rhoSmooth(SmoothNo+1:end-SmoothNo));
XShifted=round(Xnew+px);
YShifted=round(Ynew+py);

    XGap=abs(XShifted(2:end)-XShifted(1:end-1));
    YGap=abs(YShifted(2:end)-YShifted(1:end-1));
    maxGap=max([XGap;YGap]);
while maxGap>1
    addedpix=0;
gapindeces=find(XGap>1);
for i=1:length(gapindeces);
    ShiftPix=gapindeces(i)+addedpix;
    XAdd=mean([XShifted(ShiftPix:ShiftPix+1)]);
    YAdd=mean([YShifted(ShiftPix:ShiftPix+1)]);
    XShifted=[XShifted(1:ShiftPix);XAdd;XShifted(ShiftPix+1:end)];
    YShifted=[YShifted(1:ShiftPix);YAdd;YShifted(ShiftPix+1:end)];
    addedpix=addedpix+1;
end
for i=1:length(gapindeces);
    ShiftPix=gapindeces(i)+addedpix;
    XAdd=mean([XShifted(ShiftPix:ShiftPix+1)]);
    YAdd=mean([YShifted(ShiftPix:ShiftPix+1)]);
    XShifted=[XShifted(1:ShiftPix);XAdd;XShifted(ShiftPix+1:end)];
    YShifted=[YShifted(1:ShiftPix);YAdd;YShifted(ShiftPix+1:end)];
    addedpix=addedpix+1;
end
    XShifted=round(XShifted);
    YShifted=round(YShifted);
    XGap=abs(XShifted(2:end)-XShifted(1:end-1));
    YGap=abs(YShifted(2:end)-YShifted(1:end-1));
    maxGap=max([XGap;YGap]);
end
    while abs(XShifted(1)-XShifted(end))>1 || abs(YShifted(1)-YShifted(end))>1
        XShifted(end+1)=round((XShifted(1)+XShifted(end))/2);
                YShifted(end+1)=round((YShifted(1)+YShifted(end))/2);
    end
    bw = zeros(size(qq)); % Create an m by n array of 0's
idx = YShifted+((XShifted-1)*size(bw,1)); % linear index into bw
bw(idx) = 1;

