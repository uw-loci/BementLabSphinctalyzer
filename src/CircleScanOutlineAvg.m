function [outxvals, outyvals, outstdevs, outnums, outmeds, outsmooth2]=CircleScanOutlineAvg(OutlineIn, compimage)
%%This function calculates the peak-oriented circle scan from refimage
%%masked with innermask and outtermask from startpoint.  Values from circle
%%are derived from compimage.  maskout is the circle trace.  The remaining
%%outputs are x values, y values, standard deviations, and number of data
%%points for each value.

dilationfactor=1;
compimage=double(compimage);
watershedridgefilled=imfill(OutlineIn,'holes');
outdist=bwdist(watershedridgefilled);
outdist=round(outdist);
if max(max(outdist~=inf));
    for j=1:max(max(outdist))
        outmat1=compimage(outdist==j);
        numout(j)=numel(outmat1);
        val1(j)=mean(outmat1);
        med1(j)=median(outmat1);
        std1(j)=std(outmat1);
    end
    indist=bwdist(~watershedridgefilled);
    indist=round(indist);
    for j=1:max(max(indist))
        inmat1=compimage(indist==j);
        numin(j)=numel(inmat1);
        val1in(j)=mean(inmat1);
        med1in(j)=median(inmat1);
        std1in(j)=std(inmat1);
    end
    valx=[-max(max(outdist))/dilationfactor:(1/dilationfactor):(max(max(indist))-1)/dilationfactor];
end
indist2=indist-1;
indist2(indist2<0)=0;
XVals=(indist2-outdist);
XVals=XVals(:);
IVals=compimage(:);
outsmooth=smooth(XVals,IVals, .05, 'loess');
outsmooth2=zeros(size(valx));
for i = 1:length(valx)
    outsmooth2(i)=mean(outsmooth(find(XVals==valx(i))));
end
outyvals=[fliplr(val1),val1in];
outstdevs=[fliplr(std1),std1in];
outmeds=[fliplr(med1),med1in];
outnums=[fliplr(numout),numin];
outxvals=valx;