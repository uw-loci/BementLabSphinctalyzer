function tests = testRingAreaFromOutline
% Unit tests for the area enclosed by the circle scan contour at the peak,
% using a synthetic circular wound outline.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testsDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testsDir,'..','src')));
testCase.TestData.radius = 40;
testCase.TestData.outline = circleOutline(201, testCase.TestData.radius);
end

function testPeakOnOutlineGivesFilledArea(testCase)
outline = testCase.TestData.outline;
filledArea = nnz(imfill(outline,'holes'));
verifyEqual(testCase, RingAreaFromOutline(outline, 0), filledArea);
end

function testPeakOutsideOutlineGivesLargerCircle(testCase)
R = testCase.TestData.radius;
k = 10;
verifyEqual(testCase, RingAreaFromOutline(testCase.TestData.outline, -k), pi*(R+k)^2, 'RelTol', 0.05);
end

function testPeakInsideOutlineGivesSmallerCircle(testCase)
R = testCase.TestData.radius;
k = 10;
verifyEqual(testCase, RingAreaFromOutline(testCase.TestData.outline, k), pi*(R-k)^2, 'RelTol', 0.05);
end

function testAreaDecreasesAsPeakMovesInward(testCase)
areas = arrayfun(@(x) RingAreaFromOutline(testCase.TestData.outline, x), -20:20);
verifyTrue(testCase, all(diff(areas) <= 0));
end

function outline = circleOutline(imageSize, radius)
% one-pixel-wide outline of a disk centered in the image
[x, y] = meshgrid(1:imageSize);
center = (imageSize+1)/2;
disk = (x-center).^2 + (y-center).^2 <= radius^2;
outline = bwperim(disk);
end
