// Give the Mac launcher the app's icon and hide its ".command" extension in
// Finder, so it looks like an app. Called by build/buildStandalone.m:
//   osascript -l JavaScript set_launcher_icon.js <launcher> <icns file>
// Both are kept in a zip made with ditto --sequesterRsrc and restored when
// the zip is opened in Finder.
function run(argv) {
    ObjC.import('AppKit');
    var launcher = argv[0];
    var image = $.NSImage.alloc.initWithContentsOfFile(argv[1]);
    if (image.isNil()) {
        throw new Error('Cannot read the icon ' + argv[1]);
    }
    if (!$.NSWorkspace.sharedWorkspace.setIconForFileOptions(image, launcher, 0)) {
        throw new Error('Cannot set the icon of ' + launcher);
    }
    if (!$.NSFileManager.defaultManager.setAttributesOfItemAtPathError(
            $({NSFileExtensionHidden: true}), launcher, null)) {
        throw new Error('Cannot hide the extension of ' + launcher);
    }
    return 'ok';
}
