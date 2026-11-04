function tests = testClosingCheckpointFrames
% Unit tests for the closing checkpoint search (frame at which the wound is
% a given fraction open), including invalid velocity ranges.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testsDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testsDir,'..','src')));
% peak location shrinking by 1 per frame from 30 at frame 1 to 11 at frame 20
testCase.TestData.measure = 31 - (1:20);
end

function testFindsNearestFrames(testCase)
% start frame 1 (30): 2/3 open = 20 at frame 11, 1/2 open = 15 at frame 16
[frames, status] = closingCheckpointFrames(testCase.TestData.measure, 1, 20, [2/3 0.5]);
verifyEqual(testCase, status, '');
verifyEqual(testCase, frames, [11; 16]);
end

function testActualFractionsAtFoundFrames(testCase)
% frames 11 (20) and 16 (15) relative to frame 1 (30)
measure = testCase.TestData.measure;
[frames, ~, actual] = closingCheckpointFrames(measure, 1, 20, [2/3 0.5]);
verifyEqual(testCase, frames, [11; 16]);
verifyEqual(testCase, actual, measure(frames)'/measure(1), 'AbsTol', 1e-12);
verifyEqual(testCase, actual, [20/30; 15/30], 'AbsTol', 1e-12);
end

function testActualFractionIsNaNWithoutFrame(testCase)
[frames, ~, actual] = closingCheckpointFrames(testCase.TestData.measure, 1, 20, [1/4 1/3]);
verifyEqual(testCase, frames, [NaN; 20]);
verifyEqual(testCase, actual, [NaN; 11/30], 'AbsTol', 1e-12);
[~, ~, actual] = closingCheckpointFrames(testCase.TestData.measure, 20, 5, [0.75 0.5]);
verifyEqual(testCase, actual, [NaN; NaN]);
end

function testCheckpointBeyondRangeIsNaN(testCase)
% 1/4 open = 7.5 is 3.5 below frame 20 (11), more than the 1-per-frame tolerance;
% 1/3 open = 10 is exactly 1 below frame 20, so it is still accepted
frames = closingCheckpointFrames(testCase.TestData.measure, 1, 20, [1/4 1/3]);
verifyEqual(testCase, frames, [NaN; 20]);
end

function testMatchesPreviousSearchOnValidInput(testCase)
measure = [NaN NaN 26.1 25.2 24.6 23.1 22.4 21.0 19.8 19.1 18.2 17.0 16.4];
fractions = [0.667 0.5 0.333 0.9];
verifyEqual(testCase, closingCheckpointFrames(measure, 3, 13, fractions), ...
    previousSearch(measure, 3, 13, fractions));
end

function testReversedRangeGivesNaN(testCase)
[frames, status] = closingCheckpointFrames(testCase.TestData.measure, 20, 5, [0.75 0.5]);
verifyTrue(testCase, all(isnan(frames)));
verifyEqual(testCase, numel(frames), 2);
verifySubstring(testCase, status, 'not after start frame');
end

function testEqualStartAndEndGivesNaN(testCase)
[frames, status] = closingCheckpointFrames(testCase.TestData.measure, 5, 5, 0.5);
verifyTrue(testCase, isnan(frames));
verifySubstring(testCase, status, 'not after start frame');
end

function testRangeOutsideFramesGivesNaN(testCase)
[frames, status] = closingCheckpointFrames(testCase.TestData.measure, 1, 25, 0.5);
verifyTrue(testCase, isnan(frames));
verifySubstring(testCase, status, 'outside the analyzed frames');
end

function testNoPeakAtStartGivesNaN(testCase)
measure = testCase.TestData.measure;
measure(1) = NaN;
[frames, status] = closingCheckpointFrames(measure, 1, 20, 0.5);
verifyTrue(testCase, isnan(frames));
verifySubstring(testCase, status, 'no peak');
end

function testNoPeakAtEndGivesNaN(testCase)
% the previous search accepted a frame here without checking the tolerance
measure = testCase.TestData.measure;
measure(20) = NaN;
[frames, status] = closingCheckpointFrames(measure, 1, 20, 0.5);
verifyTrue(testCase, isnan(frames));
verifySubstring(testCase, status, 'no peak');
end

function testFrameWithoutPeakInsideRangeIsSkipped(testCase)
measure = testCase.TestData.measure;
measure(16) = NaN;    % the exact 1/2-open frame has no peak
frames = closingCheckpointFrames(measure, 1, 20, 0.5);
verifyEqual(testCase, frames, 15);   % frames 15 (16) and 17 (14) are equally close; earliest wins
end

function testTieUsesEarliestFrame(testCase)
measure = [20 18 16 15 15 15 12 10];   % ring area can repeat between frames
frames = closingCheckpointFrames(measure, 1, 8, 0.75);
verifyEqual(testCase, frames, 4);
end

function frames = previousSearch(measure, s, e, fractions)
% the search used before closingCheckpointFrames, for valid input
frames = nan(numel(fractions),1);
inRange = measure(s:e);
averageDistance = abs((measure(s)-measure(e))/(e-s));
for cp = 1:numel(fractions)
    d = abs(inRange - fractions(cp)*measure(s));
    m = min(d);
    if ~(m > averageDistance)
        frames(cp) = s + find(d == m) - 1;
    end
end
end
