function centroids=CentroidfromOutline(varargin)
for i=1:nargin
    images=varargin{i};
    for j=1:length(images)
        if ~isempty(images{j})
        imagedata=regionprops(bwfill(images{j},'holes'),'centroid');
        centroid(j,1:2,i)=cat(1,imagedata.Centroid);
        end
    end
end
centroids=mean(centroid,3);
        