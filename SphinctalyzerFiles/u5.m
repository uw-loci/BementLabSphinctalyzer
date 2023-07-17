figure
frmrate=12;
writerObj = VideoWriter(('SM2.avi'));
set(writerObj,'FrameRate',frmrate);
open(writerObj);
figure;

for i=1:106
    Imout(:,:,1)=VR(:,:,i)/3800;
    Imout(:,:,2)=VG(:,:,i)/3800;
    Imout(:,:,3)=VB(:,:,i)/3800;
    imshow(Imout,'InitialMagnification',400)
    pause(.01)
    frame=getframe(gca);
 writeVideo(writerObj,frame);
end
%MovieWriter
close(writerObj);
