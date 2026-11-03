function xMinStepMax = positiveXMinStepMax(xMinStepMax)
% convert a legacy negative x axis range (distance from wound center) to the
% positive convention, e.g. [-30 10 0] -> [0 10 30]. Positive ranges are
% returned unchanged.
if numel(xMinStepMax) == 3 && xMinStepMax(3) <= 0 && xMinStepMax(1) < 0
    xMinStepMax = [-xMinStepMax(3), xMinStepMax(2), -xMinStepMax(1)];
end
end
