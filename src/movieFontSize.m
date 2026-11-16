function points = movieFontSize(fontSize, fig)
% Font size in points that makes text the same fraction of the figure on
% every computer. fontSize is the size as it looks in a figure 500 points
% tall, which is the 1000x500 pixel movie figure on a Mac (72 pixels per
% inch). On Windows (96 pixels per inch) the same figure is 375 points
% tall, so the returned size is 0.75 * fontSize there.
units = fig.Units;
fig.Units = 'points';
heightInPoints = fig.Position(4);
fig.Units = units;
points = fontSize * heightInPoints / 500;
end
