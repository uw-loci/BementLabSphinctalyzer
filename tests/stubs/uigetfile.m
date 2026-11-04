function [fileName, filePath, filterIndex] = uigetfile(varargin)
% Test stub for uigetfile: returns the {fileName, filePath} pair set with
% setappdata(groot,'testUigetfile',{fileName, filePath}) instead of opening
% a file dialog. Only on the path while tests that need it run (PathFixture).
selection = getappdata(groot,'testUigetfile');
fileName = selection{1};
filePath = selection{2};
filterIndex = 1;
end
