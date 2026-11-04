function answer = questdlg(varargin)
% Test stub for questdlg: returns the answer set with
% setappdata(groot,'testQuestdlgAnswer',answer) instead of waiting for a
% click. Only on the path while tests that need it run (PathFixture).
answer = getappdata(groot,'testQuestdlgAnswer');
end
