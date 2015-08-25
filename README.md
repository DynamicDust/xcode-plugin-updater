# Xcode Plugin Updater

This script serves as an updater for all your Xcode plugins, when a new version of Xcode (or Xcode-Beta) is released.  

## Reason

In each new version of Xcode there is a new value generated for the special key in the `Info.plist` file called `DVTPlugInCompatibilityUUID` and when a plugin does not contain this special 128-bit number Xcode will not load the plugin. This makes some people angry (especially me) as most of the time, there aren't such big changes in Xcode that would cause the plugins to stop working.

So, what it means is that it can be fixed just by adding the new UUID to the `Info.plist` file of the plugin. It is possible to do manually, however when you got a lot of (20+) plugins, this becomes annoying instantly. That's why I sacrificed a few hours and created this plugin. :)

## Usage

#### Updating
1. Open Terminal.app (or similar) on your Mac
2. Run the following command (sorry for this mess, didn't have time to do it properly)  
	`curl -fsSL http://git.io/vvZMn > $TMPDIR/xcode-plugin-updater.sh && cd $TMPDIR && chmod 755 xcode-plugin-updater.sh && ./xcode-plugin-updater.sh && rm -rf xcode-plugin-updater.sh && cd`
3. All your plugins are now updated

#### Printing Xcode's UUID
1. Open Terminal.app (or similar) on your Mac
2. Run the following command  
	`curl -fsSL http://git.io/vvZMn > $TMPDIR/xcode-plugin-updater.sh && cd $TMPDIR && chmod 755 xcode-plugin-updater.sh && ./xcode-plugin-updater.sh print && rm -rf xcode-plugin-updater.sh && cd`
3. The UUID is copied to your clipboard and also printed to the command line

## Roadmap

- [x] First version
- [ ] Add compatibility for `sh` and `zsh` (currently only works with `bash`)
- [x] Print Xcode UUID (useful for developers)
- [ ] Suggestions?

## Contribution
All improvements are welcome. Please, fork the project and then open a pull request to the develop branch.

## Credits
Dominik Hádl / [@lobinick](http://twitter.com/lobinick) / [DynamicDust s.r.o](http://www.dynamicdust.com)

Created with ♥ in Prague, Czech Republic.
