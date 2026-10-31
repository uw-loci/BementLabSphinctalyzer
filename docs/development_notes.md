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
