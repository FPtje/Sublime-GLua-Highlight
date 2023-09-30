# GLua syntax highlighting in sublime

## Important

Since I (FPtje) have moved away from Sublime, I no longer have time to maintain
this repository. That means that I will not be solving bugs or updating the
definitions. Pull requests will still be accepted and merged, but issues will
not be.

## Installing throught the package manager:
1. Open Sublime
1. Install [Package Control](https://packagecontrol.io/installation)
1. Press Ctrl + Shift + P
1. type install and press enter
1. Type Gmod and press enter
1. Restart sublime text

When using sublime text 3 you will have to disable the default Lua plugin. Otherwise the default Lua plugin will remain as the default syntax highlight for all .lua files.
This can be done by adding "Lua" to the ignored_packages setting. If you don't know how to do this, do this:

1. Preferences > Settings - User
2. Add a comma after the last setting
3. Make a newline under the last setting
4. Paste the following line: `"ignored_packages": ["Vintage", "Lua"]`

(Note how "Vintage" is also there. It's a package that's disabled by default.)

## Installing manually:

1. Open sublime
2. Select Preferences > Browse Packages...
3. Copy the folder in which this README.txt is located, to the folder that just opened
4. Restart sublime


WHEN INSTALLED:
Open a lua file and go to view > Apply Syntax Highlighting > Gmod Lua. This file and the next one you'll open will have the GLua syntax.

## Credits

Thanks to @JohnnyCrazy and @djtb2924 for their wiki scrapers that provides the autocomplete entries!
