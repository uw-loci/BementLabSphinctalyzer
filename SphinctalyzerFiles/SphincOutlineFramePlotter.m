ChannelToPlot=1;
OutlineColor=1; %1 for red, 2 for green, 3 for blue
framestoplot=[9, 9]; %put in frames to plot here, as comma separated list in brackets like [5] or [1, 2, 3] or [3 5 7];


[filename, path]=uigetfile('Choose Sphinctalyzer outputs');
load([path,filename]);
ChannelName=InputCells{1,ChannelToPlot};
ImageName=(matlab.lang.makeValidName([ChannelName,'Data']));
OutlineName=(matlab.lang.makeValidName([ChannelName,'Outline']));
Ranges=[SphinctalyzerOutputs.InRange];
minrange=framestoplot;
maxrange=framestoplot;
AllPixels=[SphinctalyzerOutputs.(ImageName)];
minIntensity=double(min(AllPixels(:)));
maxIntensity=double(max(AllPixels(:)));
ImageSize=numel(SphinctalyzerOutputs(minrange).(ImageName));


for i=minrange
    figure
    BasicMatrix=repmat((double(SphinctalyzerOutputs(i).(ImageName))-minIntensity)/maxIntensity,1,1,3);
    BasicMatrix(find(SphinctalyzerOutputs(i).(OutlineName)==1)+(OutlineColor-1)*ImageSize)=1;
    imshow(BasicMatrix)
    title(num2str(i));
end