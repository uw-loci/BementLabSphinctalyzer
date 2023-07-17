frameno=188
I = medfilt2(double(H2BImages(frameno).data));
BW=ThreshOut(:,:,frameno)
[B,L] = bwboundaries(BW);
imagesc(I);
axis image
hold on
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
end