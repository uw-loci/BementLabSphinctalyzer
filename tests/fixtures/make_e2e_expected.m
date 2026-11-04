function make_e2e_expected(resultsFile)
% Record the expected results for testEndToEndAnalysis from a Results_1.xlsx
% file, saved as tests/fixtures/e2e_sub1_expected.mat.
%
% The current expected values come from a complete analysis run by hand on
% test_datasets/sphintest_-2channlel-sub1.tif (2026-11-03), with the
% parameters and the drawn outline now in tests/fixtures/e2e_sub1:
%   make_e2e_expected(['test_datasets/Sphincdata/Output_03-Nov-2026_22-52-08/' ...
%       'data_sphintest_-2channlel-sub1.tif/sphincRedo/Results_1.xlsx'])
% Only regenerate it when the analysis results are meant to change.
sheets = {'Peak Intensity','Peak Locations','Halfwidths','AUCs','Percent Above Background','Ring Area'};
for s = 1:numel(sheets)
    expected.sheets.(matlab.lang.makeValidName(sheets{s})) = readmatrix(resultsFile,'Sheet',sheets{s},'Range','B2');
end
expected.closing = readcell(resultsFile,'Sheet','Closing Velocity and Location','Range','B2');
parameters = readcell(resultsFile,'Sheet','parameters');
expected.xMinStepMax = parameters{8,2};
expected.channelNames = parameters(16,2:3);
expected.closingCheckBasis = parameters{17,2};
movies = dir(fullfile(fileparts(resultsFile),'*_scan_movietalyzerResults_1.avi'));
movie = VideoReader(fullfile(movies(1).folder, movies(1).name));
expected.movieFrames = movie.NumFrames;
expected.source = resultsFile;
save(fullfile(fileparts(mfilename('fullpath')),'e2e_sub1_expected.mat'),'expected');
end
