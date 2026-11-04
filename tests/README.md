# Tests

Run from the repository root in MATLAB R2023b:

```matlab
results = runtests('tests');
table(results)
```

| Test | What it checks |
|---|---|
| `testPositiveXMinStepMax` | Legacy negative x axis ranges (e.g. `[-30 10 0]`) are converted to positive distances from wound center (`[0 10 30]`); positive ranges are unchanged. |
| `testRingAreaFromOutline` | On a synthetic circular outline of radius R, the area enclosed by the circle scan contour at the peak is the filled outline area for a peak on the outline, ≈ π(R±k)² for a peak k pixels outside/inside, and never grows as the peak moves inward. |
| `testClosingCheckpointFrames` | The closing checkpoint search for one channel: finds the same frames as the previous search on valid input, returns NaN with a reason for a reversed or equal velocity range, a range outside the frames, or no peak at the start or end frame, skips frames without a peak, uses the earliest frame on ties, and returns the actual open fraction (value at the frame ÷ value at start) for each frame found. |
| `testUpdateChannelNames` | Renaming channels in the results .mat file on copies of the fixture: both channels, names with spaces, hyphens or leading digits, one channel, swapped names, current names with spaces, rejected names (file unchanged), unchanged names (file not rewritten), and post-processing after a rename. |
| `testPostProcessingErrors` | The post-processing window, opened on temporary copies of the fixture and driven through its control callbacks: errors are shown in dialogs and the window keeps working (deleted movie, failed save), Write All continues past a broken movie and summarizes, Save confirms, and Overwrite Existing writes movie 12 rather than movie 2. Takes about 1.5 min and opens windows. |
| `testLegacyPostProcessing` | A folder analyzed by an earlier version can still be post-processed with `createNewMovie_post`. Peak locations come out as positive distances (−1 × the earlier values), all other results (peak intensity, half-widths, AUCs, closing velocity and checkpoint frames) are unchanged, the saved x axis is converted, and the movie has all frames. The new "Ring Area" sheet is filled wherever a peak was found, and the closing check basis is saved. Checkpoint labels end in `(position)` or `(area)`, and the actual open fraction rows match the Peak Locations / Ring Area sheets. A second run with the closing check basis set to `area` changes only the checkpoint rows. Takes about 45 s and opens a figure window while the movies are written. |

## Fixtures

- `fixtures/legacy_sub1/`: the analyzed folder `Output_19-Nov-2024_15-43-27/data_sphintest_-2channlel-sub1.tif` (from `test_datasets/sphintest_-2channlel-sub1.tif`), saved with `xMinStepMax = [-28.8 9.6 0]`. Only the files post-processing reads are kept: `parameters.mat`, `parameters_post.xlsx` and `sphincRedo/sphinctalyzerResults.mat`. The test works on a temporary copy, so the fixture is never modified.
- `fixtures/legacy_sub1_expected.mat`: the `Results_1.xlsx` values produced on that folder by the code before the positive x axis change (commit `bda1fe0`), with negative peak locations. Only regenerate it if the peak calculation is intentionally changed.

## Stubs

- `stubs/questdlg.m`: returns the answer set with `setappdata(groot,'testQuestdlgAnswer',answer)` instead of waiting
  for a click. It is put on the path only by tests that need it (`PathFixture`), so it never replaces MATLAB's
  `questdlg` elsewhere.
