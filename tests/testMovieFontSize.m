classdef testMovieFontSize < matlab.unittest.TestCase
    % movieFontSize gives text the same size relative to the figure on
    % every computer (points per pixel differ between Mac and Windows), and
    % movieFontSizeOption checks saved and typed font sizes.

    methods (TestClassSetup)
        function addSource(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename('fullpath')),'..','src')));
        end
    end

    methods (Test)
        function sizeIsAFractionOfTheFigureHeight(testCase)
            fig = figure('Visible','off','Units','pixels','Position',[1 1 1000 500]);
            testCase.addTeardown(@() close(fig));
            fig.Units = 'points';
            heightInPoints = fig.Position(4);
            fig.Units = 'pixels';
            testCase.verifyEqual(movieFontSize(24, fig), 24 * heightInPoints / 500, 'AbsTol', 1e-9);
            if get(groot,'ScreenPixelsPerInch') == 72   % Mac: 1 pixel = 1 point
                testCase.verifyEqual(movieFontSize(24, fig), 24, 'AbsTol', 1e-9);
            end
            testCase.verifyEqual(fig.Units, 'pixels', 'The figure units should be restored');
        end

        function halfTheFigureGivesHalfTheSize(testCase)
            big = figure('Visible','off','Units','pixels','Position',[1 1 1000 500]);
            small = figure('Visible','off','Units','pixels','Position',[1 1 500 250]);
            testCase.addTeardown(@() close([big small]));
            testCase.verifyEqual(movieFontSize(24, small), movieFontSize(24, big) / 2, 'AbsTol', 1e-9);
        end

        function optionAcceptsNumbersFrom8To48(testCase)
            testCase.verifyEqual(movieFontSizeOption(30), 30);
            testCase.verifyEqual(movieFontSizeOption('32'), 32);
            testCase.verifyEqual(movieFontSizeOption(8), 8);
            testCase.verifyEqual(movieFontSizeOption(48), 48);
            for bad = {7, 49, 'big', [], NaN, missing, [20 30]}
                [value, isValid] = movieFontSizeOption(bad{1});
                testCase.verifyFalse(isValid);
                testCase.verifyEqual(value, getDefaultMovieFontSize());
            end
        end
    end
end
