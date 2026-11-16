function s = getDefaultMovieFontSize()
% Central definition of the default font size of the movie and "Data over
% time" figures, as it looks in the 1000x500 movie figure on a Mac (see
% movieFontSize). Used wherever no font size is saved:
%   - sphinctalyzerOutput.m  : GUI initialisation and old-format xlsx fallback
%   - get_postParameters.m   : no-file and old-format xlsx fallbacks
%   - SphinctalyzerMoviePlotterMulti.m : no font size in advancedOptions
s = 24;
end
