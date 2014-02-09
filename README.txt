Installing throught the package manager:
1. Open Sublime
2. Press Ctrl + Shift + P
3. type install and press enter
4. Type Gmod and press enter
5. Restart sublime text

When using sublime text 3 you will have to disable the default Lua plugin. Otherwise the default Lua plugin will remain as the default syntax highlight for all .lua files.
This can be done by adding "Lua" to the ignored_packages setting. If you don't know how to do this, do this:
1. Preferences > Settings - User
2. Add a comma after the last setting
3. Make a newline under the last setting
4. Paste the following line:
	"ignored_packages": ["Vintage", "Lua"]
Note how "Vintage" is also there. It's a package that's disabled by default.

Installing manually:

1. Open sublime
2. Select Preferences > Browse Packages...
3. Copy the folder in which this README.txt is located, to the folder that just opened
4. Restart sublime


WHEN INSTALLED:
Open a lua file and go to view > Apply Syntax Highlighting > Gmod Lua. This file and the next one you'll open will have the GLua syntax.