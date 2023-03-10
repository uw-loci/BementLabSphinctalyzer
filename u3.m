i=9

redim=SphinctalyzerOutputs(i).mRFP_wGBDOutline;
redavg=SphinctalyzerOutputs(i).mRFP_wGBDMeanIntensities;
redx=SphinctalyzerOutputs(i).mRFP_wGBDXDistances;
reddist=round(bwdist(redim));
redfill=imfill(redim,'holes');
reddist(~redfill)=reddist(~redfill)*-1;
redfinal=zeros(size(redim));
for j=1:length(redx)
    redfinal(reddist==redx(j))=redavg(j);
end
redfinal=redfinal-min(min(redfinal));
redfinal=redfinal./max(max(redfinal));
greenim=SphinctalyzerOutputs(i).eGFP_wGBDOutline;
greenavg=SphinctalyzerOutputs(i).eGFP_wGBDMeanIntensities;
greenx=SphinctalyzerOutputs(i).eGFP_wGBDXDistances;
greendist=round(bwdist(greenim));
greenfill=imfill(greenim,'holes');
greendist(~greenfill)=greendist(~greenfill)*-1;
greenfinal=zeros(size(greenim));
for j=1:length(greenx)
    greenfinal(greendist==greenx(j))=greenavg(j);
end

greenfinal=greenfinal-min(min(greenfinal));
greenfinal=greenfinal./max(max(greenfinal));
blueim=SphinctalyzerOutputs(i).mTagBFP_wGBDOutline;
blueavg=SphinctalyzerOutputs(i).mTagBFP_wGBDMeanIntensities;
bluex=SphinctalyzerOutputs(i).mTagBFP_wGBDXDistances;
bluedist=round(bwdist(blueim));
bluefill=imfill(blueim,'holes');
bluedist(~bluefill)=bluedist(~bluefill)*-1;
bluefinal=zeros(size(blueim));
for j=1:length(bluex)
    bluefinal(bluedist==bluex(j))=blueavg(j);
end
bluefinal=bluefinal-min(min(bluefinal));
bluefinal=bluefinal./max(max(bluefinal));
mergestack(:,:,1)=redfinal./max(max(redfinal));
mergestack(:,:,2)=greenfinal./max(max(greenfinal));
mergestack(:,:,3)=bluefinal./max(max(bluefinal));