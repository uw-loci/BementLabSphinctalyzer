function writeDefaultParameters(folder)
% Write parameters.csv and parameters.mat with the built-in defaults into
% folder, for "Load Parameters". Loading them gives the same settings as
% opening images without a parameters file. build/buildStandalone.m puts
% them next to the standalone app, where users can edit parameters.csv.
obj = defaultImageParameters('', '');
% -1 and -1: analyze all frames of each image
obj.timepointStart = -1;
obj.timepointEnd = -1;
% channel name, and the same per-channel defaults as for a new image;
% images with fewer channels use the first rows
obj.cellArray = {'channel1',1,1; 'channel2',1,0; 'channel3',1,0};
obj.channelNames = obj.cellArray(:,1)';
saveAnalysisParameters(obj, folder)
end
