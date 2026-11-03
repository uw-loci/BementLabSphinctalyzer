# Development Notes

## Skip macOS "._" files when listing results (2026-10-30)

### Problem
Analyzing images saved on a flash drive connected to a Mac skipped every image with this error:

```
Analysis of Object 1  did not go through, error message: Unable to read MAT-file
/Volumes/<drive>/.../data_<image>.tif/sphinc/._sphinctalyzerResults.mat. Not a binary MAT-file.
```

### Cause
When macOS writes a file to a drive that is not Mac-formatted (exFAT/FAT32 flash drives, some network
shares), it also creates a hidden "AppleDouble" companion file named `._<original name>` that holds Finder
metadata. Writing `sphinctalyzerResults.mat` therefore also creates `._sphinctalyzerResults.mat`.

The code found results files with `dir(fullfile(path, '*.mat'))`, then kept every name containing
`'sphinc'`. The `._` file matched that check, and `load` failed on it because it is not a real MAT-file.

The problem only occurs where macOS has written to a non-Mac-formatted drive. Windows and Linux never create
`._` files, but a drive written on a Mac carries them along when it is opened on another system.

### Fix
After each `dir` call that lists results, remove entries whose names start with `._`:

```matlab
validnames(strncmp({validnames.name}, '._', 2)) = [];
```

Applied in:
- `SphincRescue.m`: `.mat` lookup (the source of the error above) and the subfolder recursion
- `SphinctalyzerMoviePlotterMulti.m`: `.mat` lookup and the subfolder recursion
- `sphinctalyzerInitializerGUI.m`: `.avi` lookup in `sphincRedo`
- `sphinctalyzerOutput.m`: `.avi` lookup in `sphincRedo`

The unused `SphinctalyzerMoviePlotterMultinew.m`, `SphinctalyzerMoviePlotterMultiPercentage.m` and
`SphinctalyzerMoviePlotterMultiPercentageInvert.m` were not changed. Apply the same line if they are put
back into use.

### Testing
- Verified on macOS (MATLAB R2023b) with images on an exFAT flash drive: analysis completes.
- A scripted test in R2023b checked the filter on a normal folder (nothing removed, including names with
  `._` in the middle), a folder with `._` companions (only those removed), and an empty folder (no error).
- On Windows, `dir` and `strncmp` behave the same. Nothing is filtered unless the drive contains `._` files
  left by a Mac.

### For new code
Any new `dir(...)` listing of files or folders that the program reads should filter out `._` names the
same way. Alternatively, reformat Mac-only data drives as APFS or Mac OS Extended, or run
`dot_clean /Volumes/<drive>` to remove existing `._` files.

## Positive x axis (distance from wound center) in output movies (2026-11-02)

Commits: `065d915` (code), `5b975ef` (tests).

### Problem
The x axis of the line-scan movies ran from -30 to 0 (default `xMinStepMax = [-30 10 0]`), and the
"Peak Locations" sheet of `Results_N.xlsx` stored negative values, although both describe a distance
from the wound center.

### Cause
`CircleScanOutlineAvg.m` measures each pixel's signed distance to the outline (positive inside, negative
outside). `SphinctalyzerMoviePlotterMulti.m` shifts it by the centroid-to-outline distance
(`OutlineDistfromCentroid.m`), so 0 is the wound center and the plotted x equals -(distance from center).

### Fix
Only the output is changed. The scan data in `sphinctalyzerResults.mat` and the peak search in
`IntensityIntegrator.m` keep the internal signed coordinate.

`SphinctalyzerMoviePlotterMulti.m`:
- `x` is the positive distance grid, and the profiles are sampled at `-x`:
  `Zr(k, :)=interp1(XVals,Intensities,-x);`
- `set(gca,'XDir','reverse')` keeps the earlier orientation: wound center (0) on the right, maximum
  distance on the left. The curves are drawn exactly where they were before; only the tick labels lose
  their minus sign. The non-GUI defaults changed from -150..0 to 0..150 pixels.
- Peak location is stored as `(shift - PeakLocation)*micronsPerPixel`, a positive distance.
- Closing velocity is `(location at start - location at end)/time`, so it stays positive for a closing
  wound, as before. Checkpoint frames and the instantaneous velocity (an absolute value) do not depend on
  the sign and are unchanged.

`SphinctalyzerImageSlider.m`: its closing velocity uses the same convention.

Defaults: `sphinctalyzerInitializerGUI.m` uses `[0 10 30]`; `src/parameters.mat` and `src/parameters.csv`
use `[0 9.6 28.8]`.

### Backward compatibility
Earlier analyses store the negative range in `parameters.mat`, `parameters_post.xlsx` and the "parameters"
sheet of `Results_N.xlsx`. The new `positiveXMinStepMax.m` converts it when it is read
(`[-30 10 0]` -> `[0 10 30]`) and leaves positive ranges unchanged. It is applied in:
- `Image.m` (constructor), which covers every place an analysis object is built
- `get_postParameters.m` (used by `createNewMovie_post.m`)
- `sphinctalyzerOutput.m`, when parameters are reloaded from a results folder
- `SphinctalyzerMoviePlotterMulti.m`, as a safety net

Old analyses need no migration: post-processing them writes the converted range into the new results.
Loading a saved `Image` object from a `.mat` file does not run the constructor, which is why
`get_postParameters.m` converts `parameters.mat` explicitly.

The unused movie plotters (`SphinctalyzerMoviePlotter.m`, `SphinctalyzerMoviePlotterMultinew.m`,
`SphinctalyzerMoviePlotterMultiPercentage*.m`, `SphinctalyzerMoviePlotterZeroNorm*.m`,
`SphinctalyzerMultiFramePlotter*.m`) still use the negative convention.

### Testing
- In R2023b, three previously analyzed folders from `test_datasets/Sphincdata` were post-processed with
  the old and the new code (on copies, because post-processing overwrites `Results_1.xlsx`). Peak locations
  were exactly -1 x the old values; peak intensity, half-widths, AUCs, percent above background, closing
  velocity and checkpoint frames were identical; movie frames differed only in the tick-label strip.
- Not tested: data analyzed in pixels (`micronsPerPixel == 1`, none available), clicking through the GUIs,
  and `SphinctalyzerImageSlider.m` (it reads an older `Results.xls` file).
- Automated tests were added in `tests/` (see `tests/README.md`), run with `runtests('tests')` from the
  repository root:
  - `testPositiveXMinStepMax`: the conversion of legacy ranges.
  - `testLegacyPostProcessing`: post-processes `tests/fixtures/legacy_sub1` (an analyzed folder saved with
    `[-28.8 9.6 0]`) and compares the results with `tests/fixtures/legacy_sub1_expected.mat`, the values
    the code produced before this change (commit `bda1fe0`). Run against the old code, its peak-location
    and x-axis checks fail.

### For new code
- Report distances from the wound center as positive numbers. Convert at output time, not in the scan data.
- Pass any `xMinStepMax` read from a file through `positiveXMinStepMax`.
- If a plotter shown in the GUI changes the axis, keep `XDir` reversed so movies stay comparable with
  earlier ones.
- Run `runtests('tests')` before committing changes to post-processing. Regenerate
  `legacy_sub1_expected.mat` only when the peak calculation is changed on purpose.
