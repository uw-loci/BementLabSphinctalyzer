function r = getDefaultPeakSearchingRadius()
% Central definition of the default peak searching radius (in microns).
% Change the value here to apply it everywhere it is used as a fallback:
%   - sphinctalyzerOutput.m  : GUI initialisation and old-format xlsx fallback
%   - get_postParameters.m   : no-file and old-format xlsx fallbacks
%   - SphinctalyzerMoviePlotterMulti.m : nargin==13 (no moreOptions) fallback
r = 1;
end
