function imageout=DevianceMode(Data, Outline, Averages, Distances)
DistImage=bwdist(Outline);
DistImage(~imfill(Outline,'holes'))=DistImage(~imfill(Outline,'holes'))*-1;
DistImage=round(DistImage);
ZeroIm=zeros(size(DistImage))*NaN;
for i=1:length(Distances)
    ZeroIm(DistImage==Distances(i))=Averages(i);
end
DiffImage=medfilt2(double(Data),[5 5])-ZeroIm;
imageout=DiffImage;