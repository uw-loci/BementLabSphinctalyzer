# Tests

Run from the repository root in MATLAB R2023b:

```matlab
results = runtests('tests');
table(results)
```

| Test | What it checks |
|---|---|
| `testPositiveXMinStepMax` | Legacy negative x axis ranges (e.g. `[-30 10 0]`) are converted to positive distances from wound center (`[0 10 30]`); positive ranges are unchanged. |
| `testLegacyPostProcessing` | A folder analyzed by an earlier version can still be post-processed with `createNewMovie_post`. Peak locations come out as positive distances (−1 × the earlier values), all other results (peak intensity, half-widths, AUCs, closing velocity and checkpoint frames) are unchanged, the saved x axis is converted, and the movie has all frames. Takes about 30 s and opens a figure window while the movie is written. |

## Fixtures

- `fixtures/legacy_sub1/`: the analyzed folder `Output_19-Nov-2024_15-43-27/data_sphintest_-2channlel-sub1.tif` (from `test_datasets/sphintest_-2channlel-sub1.tif`), saved with `xMinStepMax = [-28.8 9.6 0]`. Only the files post-processing reads are kept: `parameters.mat`, `parameters_post.xlsx` and `sphincRedo/sphinctalyzerResults.mat`. The test works on a temporary copy, so the fixture is never modified.
- `fixtures/legacy_sub1_expected.mat`: the `Results_1.xlsx` values produced on that folder by the code before the positive x axis change (commit `bda1fe0`), with negative peak locations. Only regenerate it if the peak calculation is intentionally changed.
