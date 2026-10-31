Devs=[];
Vels=[];
for i=5
    %size(SphinctalyzerOutputs,2)-1
    DT1=DevianceMode(SphinctalyzerOutputs(i).greenData, SphinctalyzerOutputs(i).greenOutline, SphinctalyzerOutputs(i).greenMeanIntensities, SphinctalyzerOutputs(i).greenXDistances);
    DT2=DevianceMode(SphinctalyzerOutputs(i).redData, SphinctalyzerOutputs(i).redOutline, SphinctalyzerOutputs(i).redMeanIntensities, SphinctalyzerOutputs(i).redXDistances);

    DevIM=DT1;
    [D,V]=OutlineBorderVelocity(SphinctalyzerOutputs(i+1).greenOutline, SphinctalyzerOutputs(i).greenOutline, DevIM);
    Devs=[Devs;D];
    Vels=[Vels;V];
end
close all
