function areaPixels = RingAreaFromOutline(OutlineIn, peakX)
%%This function calculates the area (in pixels) enclosed by the circle scan
%%contour that passes through the peak.  The signed distance to the outline
%%is built the same way as in CircleScanOutlineAvg (positive inside the
%%outline, negative outside), and peakX is the peak position on that scan
%%(e.g. the PeakLocationX output of IntensityIntegrator).
watershedridgefilled=imfill(OutlineIn,'holes');
outdist=round(bwdist(watershedridgefilled));
indist=round(bwdist(~watershedridgefilled));
indist2=indist-1;
indist2(indist2<0)=0;
XVals=(indist2-outdist);
areaPixels=nnz(XVals>=peakX);
end
