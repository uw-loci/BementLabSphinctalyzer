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

## Ring area and area-based closing check (issue #18, 2026-11-02)

### Request
[Issue #18](https://github.com/uw-loci/BementLabSphinctalyzer/issues/18): add a wound area measurement based on the
protein ring to the output, and an option to find the frame at some percent wound closure from that area instead of
from the peak position.

### What the area measures
The circle scan (`CircleScanOutlineAvg.m`) bins intensities by each pixel's signed distance to the wound outline
(positive inside, negative outside). The peak position found by `IntensityIntegrator.m` is a value on that distance
axis, so it defines a contour that follows the outline shape at the peak. The ring area is the number of pixels inside
that contour × `micronsPerPixel`². It is computed by the new `RingAreaFromOutline.m`, which builds the distance map the
same way as `CircleScanOutlineAvg.m`. The outline is the one the scan was made on: the channel's own outline when the
reference channel is `Self`, otherwise the reference channel's outline.

For a round wound the area is close to π × (peak location)²; on `test-peak-location-exp049a.tif` the two agree within
1% for channel 2 and 4–7% for channel 1, whose outline is less circular.

### Changes
- `SphinctalyzerMoviePlotterMulti.m`:
  - new "Ring Area" sheet in `Results_N.xlsx` (µm², or pixel² when `micronsPerPixel == 1`), laid out like the other
    sheets, with the frame index in column B, channels from column C and `_Instant` change columns
  - new option `advancedOptions.closingCheckBasis`: `position` (default, unchanged output) or `area`. With `area`, the
    checkpoint frames are found on the ring area instead of the peak location, using the same search, and labeled
    e.g. `frame at 66.7% open (area)`. Closing velocity stays position-based.
  - the "parameters" sheet now has 17 rows: row 16 `channelNames`, row 17 `closing check basis`
- `save_post_parameters.m` / `get_postParameters.m`: save and read row 17. `closingCheckBasisOption.m` turns the
  stored value into `area` or `position`; empty or missing values (files from earlier versions) give `position`.
- `sphinctalyzerOutput.m` (post-processing GUI):
  - "Check Basis" popup ({Peak position, Ring area}) under "Closing Check", restored from the results file
  - "Ring Area" in the data-over-time dropdown; results without the sheet show a message to write the movie again
  - `update_movieOptions` now reads the advanced options for any parameters sheet with 15 or more rows (it required
    exactly 15, so 16- and 17-row sheets were skipped)

### Notes
- Area fractions are not radius fractions: area ∝ r², so 50% of the starting area is reached at about 70.7% of the
  starting radius. Area-based checkpoints are therefore reached earlier than position-based ones with the same
  fractions (on exp049a channel 1: 66.7% at frame 20 by area vs. frame 25 by position).
- The checkpoint search kept its existing behavior here, including a single `try` around all channels. This was
  changed afterwards; see "Closing checkpoints searched per channel" below.
- The image data panel in the post-processing window did not show the ring area at first; see "Ring area and
  frame lookup in the image data table" below.

### Testing
- `tests/testRingAreaFromOutline.m`: synthetic circular outline (areas within 2% of π(R±k)²).
- `tests/testLegacyPostProcessing.m`: the existing checks still pass with the default basis, which shows its output is
  unchanged; added checks for the Ring Area sheet, the saved basis, and a second run with the `area` basis.
- Real data (`Output_02-Feb-2025_15-30-02/data_test-peak-location-exp049a.tif`, on copies): both bases run, and
  results other than the checkpoint rows are identical.
- Post-processing GUI, driven through its control callbacks in R2023b: the basis is restored from the results file,
  the Ring Area plot is drawn, and switching the basis updates the option. Not tested by hand: the layout of the new
  popup on screen, and the message for results files without a "Ring Area" sheet.

## Closing checkpoints searched per channel (2026-11-03)

### Problem
The search for the "frame at X% open" checkpoints in `SphinctalyzerMoviePlotterMulti.m` ran inside one `try` around
all channels. An error in one channel was printed and every remaining channel's checkpoints were left empty. Errors
came from:
- a velocity range whose end frame is not after its start frame. The d1 test dataset
  (`Output_24-Jul-2025_16-00-23/data_sphintest_-2channlel.tif`) was saved with `[20 5]`; the frame range is empty
  and the assignment fails. The velocity-range boxes only checked for two positive numbers, so such ranges could be
  saved.
- a range outside the analyzed frames (index error)
- no peak (NaN) at the start frame: the target is NaN and `find` returns nothing
- two frames equally close to the target: `find` returns two frames. More likely with the ring area basis, whose
  values are whole pixel counts and can repeat.

A quieter problem: with no peak at the end frame, the tolerance (average change per frame) was NaN, so `min > NaN`
was false and a frame was accepted however far it was from the target.

### Fix
- New `closingCheckpointFrames.m` searches one channel. If the range is not valid (not whole numbers, end not after
  start, outside the analyzed frames, or no peak at the start or end frame) all checkpoints are NaN and the returned
  status says why. Otherwise the search is the same as before; frames without a peak inside the range are skipped,
  and on a tie the earliest frame is used (logged).
- `SphinctalyzerMoviePlotterMulti.m` calls it once per channel, each in its own `try`, for both the position and the
  area basis. Closing velocity is left empty when the range is not valid.
- `sphinctalyzerOutput.m`: the velocity-range boxes (C1-C3) reject a range whose end is not after its start.

### Impact on existing results
A read-only scan of 89 `Results_*.xlsx` files in `test_datasets/Sphincdata` (178 channels; 130 files with an older
layout were skipped) found no channel whose checkpoint frames change. The only invalid ranges were d1's two channels,
which are empty before and after; they now log e.g. "velocity end frame (5) is not after start frame (20)".

### Testing
- `tests/testClosingCheckpointFrames.m`: normal search (same frames as the previous search), checkpoint beyond the
  range, reversed and equal ranges, range outside the frames, no peak at start or end, a frame without a peak
  inside the range, and ties.
- d1, d2 and d4 post-processed again: all Results sheets identical to the previous output.
- Post-processing GUI, driven through the control callbacks: `20 5` and `12 12` are refused with an error dialog
  and the previous range is restored; `12 28` is accepted.

## Ring area and frame lookup in the image data table (2026-11-03)

### Changes
`sphinctalyzerOutput.m`, image data table next to the image:
- New "Ring Area" row after "% Abv Backg", filled from the "Ring Area" sheet. Results from earlier versions have no
  such sheet and show "N/A". "Closing Vel" and the checkpoint rows move down one row.
- Values are now looked up by frame number. The table used the slider position as the sheet column
  (`sheet(m, iTimepoint)`), but the slider counts from the first analyzed frame while the sheets (read from `B2`
  since `fe9548d`) start at frame 1. Whenever an analysis did not start at frame 1, the table showed another frame's
  values: on `test-peak-location-exp049a.tif` (frames 10-30) the title said frame 10 and the table showed frame 1
  (all NaN). It now uses `timepointStart + slider position - 1` and the frame-index column (`xlsFrameNums`); a frame
  not in the results shows "N/A". The Results files and the data-over-time plot were not affected.

### Results files from before 18 Jul 2025
Results written before `0af2809` ("Saving the measurements in columns") have frames across columns and channels in
rows. The GUI reader has assumed frames down rows since March 2026, so for these files the table already showed values
from the wrong cells; it now shows "N/A" for the measurements. Writing the movie again ("Write One") rewrites the
Results file in the current layout.

### Testing
Post-processing GUI on exp049a, driven through the control callbacks:
- new results: every row (peak intensity, location, half-width, AUC, % above background, ring area) equals frame 10
  in `Results_1.xlsx`; closing velocity and the `(area)` checkpoint rows follow
- results in the pre-July-2025 layout: the table loads, measurements show "N/A", closing velocity and checkpoints show

## Closing check basis in labels, and actual open fraction (2026-11-03)

### Request
1. The closing check can be based on the peak position or on the ring area, but only the area labels said so
   ("frame at 66.7% open (area)"); the position labels read "frame at 66.7% open".
2. Each checkpoint reports the frame closest to the target fraction, not how open the wound actually is at that frame.

### Changes
- Labels name the basis for both options: `frame at 66.7% open (position)` / `frame at 66.7% open (area)`.
- `closingCheckpointFrames.m` returns a third output, the actual open fraction at each checkpoint frame:
  value at that frame ÷ value at the velocity start frame, where the value is the peak location or the ring area
  (the same quantity the target is computed from). NaN where no frame was found.
- `SphinctalyzerMoviePlotterMulti.m`:
  - "Closing Velocity and Location" gets one row per checkpoint after the checkpoint-frame rows, e.g.
    `actual open fraction at 66.7% frame (area)` = 0.659. The existing rows keep their positions.
  - the command window prints the basis ("Closing check based on the ring area (um^2)") and, per checkpoint, e.g.
    "Channel 1: frame at 66.7% open (area) is frame 20, actual open fraction 65.9% (1090.36 of 1655.30 um^2)".
- `sphinctalyzerOutput.m`, image data table: checkpoint and fraction rows are found by their labels; each checkpoint
  cell shows the frame and the actual fraction, e.g. `20 (65.9%)`. Results without fraction rows show the frame only;
  labels without a basis (earlier versions, peak position only) are shown with " (position)".

### Compatibility
- Checkpoint frames, closing velocity and all other sheets are unchanged; only the label text and the appended rows
  are new.
- Scripts outside this repository that look up rows by label text must use the new labels
  ("frame at 66.7% open" is now "frame at 66.7% open (position)").
- An older version of the GUI opening a new Results file lists the fraction rows as additional checkpoint rows, with
  their own labels.

### Testing
- `tests/testClosingCheckpointFrames.m`: actual fractions at found frames; NaN without a frame or for an invalid range.
- `tests/testLegacyPostProcessing.m`: velocity and checkpoint-frame rows still equal the saved expected values; the
  fraction rows equal the Peak Locations / Ring Area values at the frame ÷ the start value; labels end in
  `(position)` or `(area)`.
- exp049a, both bases: frames and closing velocity unchanged, fractions match the sheets (e.g. area basis channel 1:
  frames 20, 23, 30 at 65.9%, 51.0%, 35.6%).
- Post-processing GUI, driven through the control callbacks: new results show `20 (65.9%)`; results without fraction
  rows show `20`; older results show `frame at 66.7% open (position)`.
