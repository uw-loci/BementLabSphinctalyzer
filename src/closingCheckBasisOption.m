function basis = closingCheckBasisOption(value)
% return the closing check basis saved in the post-processing parameters:
% 'area' (ring area) or 'position' (peak location, the default). Empty,
% missing or unknown values, e.g. from files saved by earlier versions,
% give 'position'.
basis = 'position';
if (ischar(value) || (isstring(value) && isscalar(value) && ~ismissing(value))) && strcmpi(strtrim(value),'area')
    basis = 'area';
end
end
