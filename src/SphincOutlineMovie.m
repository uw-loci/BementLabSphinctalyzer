ChannelToPlot=1;
OutlineColor=1; %1 for red, 2 for green, 3 for blue
frmrate=2; %Frame rate
[filename, path]=uigetfile('Choose Sphinctalyzer outputs');
load([path,filename]);
ChannelName=InputCells{1,ChannelToPlot};
ImageName=(matlab.lang.makeValidName([ChannelName,'Data']));
OutlineName=(matlab.lang.makeValidName([ChannelName,'Outline']));
Ranges=[SphinctalyzerOutputs.InRange];
minrange=min(find(Ranges==1));
maxrange=max(find(Ranges==1));
AllPixels=[SphinctalyzerOutputs.(ImageName)];
minIntensity=double(min(AllPixels(:)));
maxIntensity=double(max(AllPixels(:)));
ImageSize=numel(SphinctalyzerOutputs(minrange).(ImageName));
[savename,savepath]=uiputfile({'*.avi'},'Save Graph Movie',[path,'ScanMovie']);
writerObj = VideoWriter(strcat(savename));
set(writerObj,'FrameRate',frmrate);
open(writerObj);
figure;
for i=minrange:maxrange
    BasicMatrix=repmat((double(SphinctalyzerOutputs(i).(ImageName))-minIntensity)/maxIntensity,1,1,3);
    BasicMatrix(find(SphinctalyzerOutputs(i).(OutlineName)==1)+(OutlineColor-1)*ImageSize)=1;
    imshow(BasicMatrix)
        pause(.01)
frame=getframe(gcf);
 writeVideo(writerObj,frame);
end
%MovieWriter
close(writerObj);
movefile(savename,savepath)
close gcf