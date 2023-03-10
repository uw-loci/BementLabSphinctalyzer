%function [RadialComp,OrthogonalComp]=SphinctalyzerVectorCorrector(X, Y, V, Boundary)
%This function takes the input of a vector in cartesian coordinates and
%breaks it into components orthogonal and radial to an arbitrary closed
%path boundary using a weighted nearest-point approach.
%Inputs: X and Y are the origin of the vector. V is the vector as [X, Y].  Boundary is a closed binary contour.
%Outputs: RadialComp is radial component of original vector (+ is
%counter-clockwise),OrthogonalComp is orthogonal component of original
%vector (Inward is defined as positive)

OriginMat=zeros(size(Boundary));
OriginMat(Y, X) = 1;
OriginDist = double(bwdist(OriginMat));
Yindex=repmat([1:size(OriginMat,1)]',1, size(OriginMat,2));
Xindex=repmat([1:size(OriginMat,2)], size(OriginMat,1),1);
DistValues=OriginDist(logical(Boundary));
YVals=Yindex(logical(Boundary));
XVals=Xindex(logical(Boundary));
MaxDist=max(DistValues);
MaxX=XVals(find(DistValues==MaxDist,1));
MaxY=YVals(find(DistValues==MaxDist,1));
Bounds=bwtraceboundary(imfill(Boundary), [MaxY, MaxX], 'NW',8,Inf, 'counterclockwise');
BoundIndex=(Bounds(:,2)-1).*size(OriginMat,1)+Bounds(:,1);
DistancesInOrder=-OriginDist(BoundIndex);
[peaks, locs]=findpeaks(DistancesInOrder);
maxpeak=max(peaks);
peakthresh=maxpeak*1.1;
GoodPeaks=peaks(peaks>=peakthresh);
GoodLocs=locs(peaks>=peakthresh);
PeakIndeces=BoundIndex(GoodLocs);
PeakYs=Yindex(PeakIndeces);
PeakXs=Xindex(PeakIndeces);
SurfNormX=(X-PeakXs)/GoodPeaks.^2;
SurfNormY=(Y-PeakYs)/GoodPeaks.^2;






