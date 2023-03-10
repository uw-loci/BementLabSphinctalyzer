function [Devs, Velocities]=OutlineBorderVelocity(CurrentOutline, PreviousOutline,DevianceImage)
%DevianceImage=medfilt2(DevianceImage,[10 10]);
DistImage=bwdist(PreviousOutline);
DistImage(~imfill(PreviousOutline,'holes'))=DistImage(~imfill(PreviousOutline,'holes'))*-1;
IndexImage=DistImage.*CurrentOutline;
cent=regionprops(imfill(CurrentOutline,'holes'),'Centroid');
roundCent=ceil(cent.Centroid);
py=roundCent(2);
xs=find(CurrentOutline(ceil(cent.Centroid(2)),:)==1);
px=xs(end);
B=bwtraceboundary(imfill(CurrentOutline,'holes'),[py,px],'N',8,Inf,'counterclockwise');
Velocities=IndexImage(B(:,1)+(B(:,2)-1)*size(IndexImage,2));
Velocities=Velocities-mean(Velocities);
Devs=DevianceImage(B(:,1)+(B(:,2)-1)*size(IndexImage,2));
Coords=fliplr(B(1:end,:));
CoordsZero=Coords-repmat(roundCent,size(Coords,1),1);
[theta,rho]=cart2pol(CoordsZero(:,1),CoordsZero(:,2));
figure(1)
%theta=smooth(theta,5);
%Devs=smooth(double(Devs),5);
plot(wrapTo360(rad2deg(theta(2:end))),Velocities(2:end))%,1:(length(Velocities)-1))
hold on
figure(2)
plot(wrapTo360(rad2deg(theta(2:end))),Devs(2:end))%,1:(length(Velocities)-1))
hold on
figure(3)
scatter(Devs(2:end),Velocities(2:end))
hold on
Devs=Devs(2:end);
Velocities=Velocities(2:end);