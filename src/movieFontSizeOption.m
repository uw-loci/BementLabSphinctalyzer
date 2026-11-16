function [fontSize, isValid] = movieFontSizeOption(value)
% Movie font size from a saved value or user input: a number from 8 to 48
% (a number in text is accepted). Anything else, including a missing value,
% gives the default (getDefaultMovieFontSize) and isValid = false.
if ischar(value) || isstring(value)
    value = str2double(value);
end
isValid = isnumeric(value) && isscalar(value) && isfinite(value) && value >= 8 && value <= 48;
if isValid
    fontSize = double(value);
else
    fontSize = getDefaultMovieFontSize();
end
end
