function out = applyDisplacementFieldGPU(in,D,method,fillVal)
xGrid = (1:size(D,2));
yGrid = (1:size(D,1));
xGridg=gpuArray(xGrid);
yGridg=gpuArray(yGrid);
        
    [xGrid,yGrid] = meshgrid(xGridg,yGridg);
    
    % Now map output grid into source image coordinate system using additive
    % offsets in D.
    xGrid = xGrid + D(:,:,1);
    yGrid = yGrid + D(:,:,2);
    
    out = interp2d(in,xGrid,yGrid,method,fillVal);

