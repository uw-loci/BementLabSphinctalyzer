function shifts=OutlineDistfromCentroid(centroids, varargin);
    images=varargin{1};
    for j=1:length(images)
        imblank=zeros(size(images{j}));
        centroid=round(centroids(j,1:2));
        imblank(centroid(2), centroid(1))=1;
        centroiddist=bwdist(imblank);
        for i = 1:length(varargin)
            imoutline=varargin{i};
            imoutline=imoutline{j};
            shifts(i,j)=mean(centroiddist(find(imoutline==1)));
        end
    end
    
            
            