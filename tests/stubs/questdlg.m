function answer = questdlg(varargin)
% Test stub for questdlg: returns the answer set with
% setappdata(groot,'testQuestdlgAnswer',answer) instead of waiting for a
% click, and keeps the question in getappdata(groot,'testQuestdlgQuestion')
% for the test to check. Only on the path while tests that need it run
% (PathFixture).
setappdata(groot,'testQuestdlgQuestion',varargin{1});
answer = getappdata(groot,'testQuestdlgAnswer');
end
