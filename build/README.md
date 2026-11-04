# Building the standalone app

`buildStandalone.m` builds the Sphinctalyzer standalone app for the platform it runs on, with MATLAB R2023b and
MATLAB Compiler. Nothing is moved into or out of `src`.

## Build

1. Commit your changes (the build refuses uncommitted changes in `src` or `bfmatlab`, so every build matches a commit).
2. Set the version in `src/sphinctalyzerVersion.m` (it is also shown in the main window title).
3. In MATLAB R2023b:
   ```matlab
   addpath('<repository>/build')
   buildStandalone
   ```
   Options: `buildStandalone('SkipTests', true)` skips the tests; `buildStandalone('AllowUncommitted', true)` builds
   with uncommitted changes (for trying things out, not for a release).

The script:
1. checks the MATLAB release, MATLAB Compiler and git, and records the commit
2. runs `runtests('tests')` and stops if a test fails (about 2 minutes)
3. runs `mcc` with `src` and `bfmatlab` added where they are, into a new folder in `build/output`, with the startup
   message "Launching Sphinctalyzer v<version> <platform> standalone built on <date>..."
4. on a Mac, sets the app to always use the light appearance (`NSRequiresAquaSystemAppearance` in its `Info.plist`;
   below) and adds `Launch Sphinctalyzer.command` (below)
5. writes `build_info.txt` (version, platform, MATLAB version, commit, date, test result)
6. zips the folder (on a Mac with `ditto`, which keeps the app bundle intact)

Output, in `build/output` (not tracked by git):
```
Sphinctalyzer_v0.3.0_MACintel2023b_20261104/
    Launch Sphinctalyzer.command      double-click to start (Mac)
    sphinctalyzerInitializerGUI.app
    run_sphinctalyzerInitializerGUI.sh
    build_info.txt, readme.txt, ...   (files from MATLAB Compiler)
Sphinctalyzer_v0.3.0_MACintel2023b_20261104.zip   attach this to the GitHub release
```
The platform part of the name follows the earlier releases: `MACintel`, `MacMchips`, `Windows`.

Bio-Formats (`bfmatlab`) does not need to be inside `src`: `bfCheckJavaPath.m` finds `bioformats_package.jar` next to
itself, wherever the folder is inside the app.

## Platforms

- **Mac (Intel)**: build on an Intel Mac (`computer('arch')` is `maci64`).
- **Mac (M-series)**: build on an Apple-silicon Mac with the Apple-silicon MATLAB R2023b (`maca64`). An Intel Mac
  cannot build it.
- **Windows**: build on Windows (`win64`); the zip is made with MATLAB's `zip` and has no launcher (the `.exe` is
  started by double-clicking).

Users install the MATLAB Runtime R2023b for their platform (links in the release notes).

## Mac dark mode

When macOS is in dark mode, the app's scroll bars, table text and menus followed dark mode while its windows stayed
light: dark scroll bars, white text in the data table, unreadable "Check Basis" choices. The build therefore sets
`NSRequiresAquaSystemAppearance` to true in the app's `Info.plist`, so the app always uses the light appearance, and
fails if the setting is missing afterwards. The app is not code-signed, so editing `Info.plist` is safe. The tables
and list boxes also set black text on a white background in the code.

## Mac launcher: Launch Sphinctalyzer.command

Generated from `launch_sphinctalyzer.command.template`. Double-clicking it opens Terminal and:
- finds the MATLAB Runtime R2023b (`/Applications/MATLAB/MATLAB_Runtime/R2023b`, or the folder in `MCR_ROOT`);
  if it is missing, shows the download link
- checks the package matches the Mac (an M-series package does not run on Intel; an Intel package on an M-series Mac
  needs Rosetta)
- deactivates an active conda environment (avoids library conflicts)
- removes the macOS download quarantine from the app in its folder
- starts the app with `run_sphinctalyzerInitializerGUI.sh` and saves its console output to
  `~/Library/Logs/Sphinctalyzer/Sphinctalyzer_v<version>_<date_time>.log`; if the app stops with an error, the
  window stays open and shows where the log is (useful when reporting a problem)

The first time, macOS may block the downloaded `.command` file ("cannot be opened because it is from an unidentified
developer"): right-click it, choose Open, and confirm. After that a double-click is enough.

## Check a build before releasing

The tests check the code, not the built app. Before attaching a zip to a release, unzip it in a new folder, start it
with `Launch Sphinctalyzer.command`, and check by hand:
- Open Image(s) with `test_datasets/sphintest_-2channlel-sub1.tif` (confirms Bio-Formats works in the app)
- Sphinctalyze, reusing the saved outline, and the results window
- Update Parameters (the default parameters are saved in the app's folder)
