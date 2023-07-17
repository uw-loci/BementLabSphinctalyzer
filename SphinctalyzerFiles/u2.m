i=15

CurrentIm=double(SphinctalyzerOutputs(i).greenData);
% imageout=DevianceMode(CurrentIm, SphinctalyzerOutputs(i).greenOutline, SphinctalyzerOutputs(i).greenMeanIntensities, SphinctalyzerOutputs(i).greenXDistances);
% imageout=imageout-min(min(imageout));
% imageout=imageout./max(max(imageout));
% CurrentIm=imageout;
CurrentIm=CurrentIm/2000;
CurrentIm(CurrentIm>=1)=.996;

imshow(imoverlay(CurrentIm, imdilate(SphinctalyzerOutputs(i).greenOutline,strel('disk',1)),[ 0 1 0]))

imshow(SphinctalyzerOutputs(1).greenData