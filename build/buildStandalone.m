function zipFile = buildStandalone(varargin)
% Build the Sphinctalyzer standalone app for this computer's platform.
%
% Run from any folder in MATLAB R2023b with MATLAB Compiler:
%   buildStandalone                       % run the tests, build, zip
%   buildStandalone('SkipTests', true)    % build without running the tests
%   buildStandalone('AllowUncommitted', true)  % build with uncommitted changes in src/bfmatlab
%
% Output (build/output, not tracked by git):
%   Sphinctalyzer_v<version>_<platform>2023b_<yyyymmdd>/   app files from MATLAB Compiler,
%       "Launch Sphinctalyzer.command" (Mac) and build_info.txt
%   Sphinctalyzer_v<version>_<platform>2023b_<yyyymmdd>.zip
% The version comes from src/sphinctalyzerVersion.m. See build/README.md.

options = inputParser;
options.addParameter('SkipTests', false, @islogical);
options.addParameter('AllowUncommitted', false, @islogical);
options.parse(varargin{:});
options = options.Results;

buildDir = fileparts(mfilename('fullpath'));
repo = fileparts(buildDir);
srcDir = fullfile(repo,'src');
bfDir = fullfile(repo,'bfmatlab');
mainFile = fullfile(srcDir,'sphinctalyzerInitializerGUI.m');

% checks
if ~strcmp(version('-release'), '2023b')
    error('Build with MATLAB R2023b (this is R%s): the release notes ask users for the R2023b Runtime.', version('-release'))
end
if ~license('test','Compiler') || isempty(ver('compiler'))
    error('MATLAB Compiler is required to build the standalone app.')
end
[gitStatus, changes] = system(sprintf('git -C "%s" status --porcelain -- src bfmatlab', repo));
if gitStatus ~= 0
    error('Could not run git in %s: %s', repo, changes)
end
if ~isempty(strtrim(changes)) && ~options.AllowUncommitted
    error(['There are uncommitted changes in src or bfmatlab:\n%s\n' ...
        'Commit them so the build matches a commit, or use buildStandalone(''AllowUncommitted'', true).'], changes)
end
[~, commit] = system(sprintf('git -C "%s" rev-parse --short HEAD', repo));
commit = strtrim(commit);
if ~isempty(strtrim(changes))
    commit = [commit ' (with uncommitted changes)'];
end

addpath(srcDir);
appVersion = sphinctalyzerVersion();
arch = computer('arch');
switch arch
    case 'maci64'
        platform = 'MACintel';
        platformText = 'Mac(intel 64-bit)';
        runtimeUrl = 'https://ssd.mathworks.com/supportfiles/downloads/R2023b/Release/0/deployment_files/installer/complete/maci64/MATLAB_Runtime_R2023b_maci64.dmg.zip';
    case 'maca64'
        platform = 'MacMchips';
        platformText = 'Mac(M-series)';
        runtimeUrl = 'https://ssd.mathworks.com/supportfiles/downloads/R2023b/Release/10/deployment_files/installer/complete/maca64/MATLAB_Runtime_R2023b_Update_10_maca64.dmg';
    case 'win64'
        platform = 'Windows';
        platformText = 'Windows(64-bit)';
        runtimeUrl = '';
    otherwise
        error('Unsupported platform: %s', arch)
end
buildDate = datetime('now');
packageName = sprintf('Sphinctalyzer_v%s_%s2023b_%s', appVersion, platform, char(buildDate,'yyyyMMdd'));
outputRoot = fullfile(buildDir,'output');
packageDir = fullfile(outputRoot, packageName);
zipFile = fullfile(outputRoot, [packageName '.zip']);
fprintf('Building %s (commit %s)\n', packageName, commit);

% tests
testSummary = 'not run';
if ~options.SkipTests
    fprintf('Running the tests...\n');
    startFolder = cd(repo);
    restoreFolder = onCleanup(@() cd(startFolder));
    results = runtests('tests');
    clear restoreFolder
    testSummary = sprintf('%d passed, %d failed', nnz([results.Passed]), nnz([results.Failed] | [results.Incomplete]));
    if any([results.Failed] | [results.Incomplete])
        error('Tests failed (%s); the app was not built.', testSummary)
    end
    fprintf('Tests: %s\n', testSummary);
end

% build into a fresh folder outside src
if isfolder(packageDir)
    rmdir(packageDir, 's');
end
mkdir(packageDir);
if isfile(zipFile)
    delete(zipFile);
end
addpath(bfDir);
startMessage = sprintf('-startmsg,"Launching Sphinctalyzer v%s %s standalone built on %s..."', ...
    appVersion, platformText, char(buildDate,'MM/dd/yyyy'));
mcc('-v', ...
    '-W', sprintf('main:Sphinctalyzer%s,version=%s', appVersion, appVersion), ...
    '-d', packageDir, ...
    '-a', srcDir, ...
    '-a', bfDir, ...
    '-R', startMessage, ...
    mainFile);

% Mac launcher next to the app files
[~, mainName] = fileparts(mainFile);
if ismac
    % use the light appearance even when macOS is in dark mode: otherwise
    % scroll bars, table text and menus follow dark mode while the windows
    % are light, and some text becomes unreadable
    infoPlist = fullfile(packageDir, [mainName '.app'], 'Contents', 'Info.plist');
    system(sprintf('/usr/libexec/PlistBuddy -c "Delete :NSRequiresAquaSystemAppearance" "%s" 2>/dev/null', infoPlist));
    [plistStatus, plistOutput] = system(sprintf( ...
        '/usr/libexec/PlistBuddy -c "Add :NSRequiresAquaSystemAppearance bool true" "%s"', infoPlist));
    [~, plistValue] = system(sprintf('/usr/libexec/PlistBuddy -c "Print :NSRequiresAquaSystemAppearance" "%s"', infoPlist));
    if plistStatus ~= 0 || ~strcmp(strtrim(plistValue), 'true')
        error('Could not set the light appearance in %s: %s', infoPlist, plistOutput)
    end

    template = fileread(fullfile(buildDir,'launch_sphinctalyzer.command.template'));
    launcher = replace(template, ...
        {'{{VERSION}}','{{PLATFORM}}','{{ARCH}}','{{RUN_SCRIPT}}','{{APP_BUNDLE}}','{{RUNTIME_URL}}'}, ...
        {appVersion, platformText, arch, ['run_' mainName '.sh'], [mainName '.app'], runtimeUrl});
    launcherFile = fullfile(packageDir,'Launch Sphinctalyzer.command');
    writelines(launcher, launcherFile, 'LineEnding', '\n');
    fileattrib(launcherFile, '+x', 'a');
end

% build information
info = {sprintf('Sphinctalyzer v%s', appVersion), ...
    sprintf('Platform: %s (%s)', platformText, arch), ...
    sprintf('Built: %s with MATLAB %s', char(buildDate,'yyyy-MM-dd HH:mm'), version), ...
    sprintf('Commit: %s', commit), ...
    sprintf('Tests: %s', testSummary)};
writelines(info, fullfile(packageDir,'build_info.txt'));

% zip; ditto keeps the app bundle's permissions and links on a Mac
if ismac
    [zipStatus, zipOutput] = system(sprintf('ditto -c -k --sequesterRsrc --keepParent "%s" "%s"', packageDir, zipFile));
    if zipStatus ~= 0
        error('Could not create %s: %s', zipFile, zipOutput)
    end
else
    zip(zipFile, packageName, outputRoot);
end
zipInfo = dir(zipFile);
fprintf('\nBuilt %s\n  folder: %s\n  zip:    %s (%.1f MB)\n', packageName, packageDir, zipFile, zipInfo.bytes/1e6);
end
