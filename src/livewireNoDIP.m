% cbgetcoords returns coordinates in (col,row) format with origin at (0,0). This
% function takes those coordinates (ps, pd), and converts them to (row,col) coordinates
% with origin at (1,1). The coordinates in path are in (col,row) format with origin at (0,0). 
function path = livewireNoDIP(im, ps, pd, w)
%save test im ps pd

if nargin < 4
        w = 5; % Margin around the cropped image (im will be cropped so that dijkstra does not take for ever to run).
end
    
        
% Coordinates are two-dimensional.
if numel(ps) == 3
        z = ps(3);
        ps = ps(1:2);
        pd = pd(1:2);
else
        z = 0;        
end        

% Crop image.        
minc = max(1, min(ps(1), pd(1))-w);
maxc = min(size(im, 2), max(ps(1), pd(1))+w);
minr = max(1, min(ps(2), pd(2))-w);
maxr = min(size(im, 1), max(ps(2), pd(2))+w);

if ndims(im) == 3
        im = squeeze(im(minr:maxr, minc:maxc, 0));
else
        im = im(minr:maxr, minc:maxc);
end

% Adjust source and destination coordinates.
ps = ps - [minc minr]+1;
pd = pd - [minc minr]+1;
                        
% Make sure the cropped image is a matrix and invert it so that high intensities become low ones.
im = double(1+max(max(im))-im);

% The nodes for dijkstra are each one of the pixels. These lines create the arrays of coordinates.
[rnodes cnodes] = meshgrid(1:size(im, 1), 1:size(im, 2));
cnodes = reshape(cnodes, [numel(cnodes), 1]);
rnodes = reshape(rnodes, [numel(rnodes), 1]);

nodes = [rnodes cnodes];

% Then we consider as neighbors those pixels that are at most sqrt(2) apart. We add 0.1 because Radjacency checks for distances < maxd, not <= maxd.
maxd = sqrt(2) + 0.1;
weights = Radjacency(nodes', maxd);

% (r(ii), c(ii)) are the indices of each of the pairs of neighboring pixels.
[r c] = find(weights);

% Assign to each of these pairs the weight/distance represented by the intensity of the second element (destination) in the couple.
for ii = 1:numel(r)
        weights(c(ii), r(ii)) = im(nodes(r(ii), 1), nodes(r(ii), 2)); 
        weights(r(ii), c(ii)) = im(nodes(c(ii), 1), nodes(c(ii), 2));
end        

% s and d contain the indeces of the source and destination pixels.
s = find((nodes(:, 1) == ps(2)) & (nodes(:, 2) == ps(1)));
d = find((nodes(:, 1) == pd(2)) & (nodes(:, 2) == pd(1)));

% Find lowest cost (highest intensity) path between source and destination.
p = dijkstra(weights, s, d);

% Convert indeces to coordinates.
path = nodes(p, 2:-1:1);

% Readjust taking into account that image had been cropped.
path = path + repmat([minc-1 minr-1], [size(path, 1), 1]);

% Return 3D coordinates.
path = [path repmat(z, [size(path, 1), 1])];
