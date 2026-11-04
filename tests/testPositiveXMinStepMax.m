function tests = testPositiveXMinStepMax
% Unit tests for converting legacy negative x axis ranges to positive
% distances from wound center.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testsDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testsDir,'..','src')));
end

function testLegacyDefaultIsConverted(testCase)
verifyEqual(testCase, positiveXMinStepMax([-30 10 0]), [0 10 30]);
end

function testLegacyMicronRangeIsConverted(testCase)
verifyEqual(testCase, positiveXMinStepMax([-28.8 9.6 0]), [0 9.6 28.8], 'AbsTol', 1e-12);
end

function testLegacyRangeNotEndingAtZeroIsConverted(testCase)
verifyEqual(testCase, positiveXMinStepMax([-40 10 -10]), [10 10 40]);
end

function testPositiveRangeIsUnchanged(testCase)
verifyEqual(testCase, positiveXMinStepMax([0 10 30]), [0 10 30]);
verifyEqual(testCase, positiveXMinStepMax([5 5 25]), [5 5 25]);
end

function testNonRangeValueIsUnchanged(testCase)
% SphinctalyzerMoviePlotterMulti uses 0 as a placeholder when run without GUI input
verifyEqual(testCase, positiveXMinStepMax(0), 0);
end
