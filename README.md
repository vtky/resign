# resign
XCode Project to resign .ipa files


## How to use

1. Put ipa to be resigned in the ipa_to_resign folder
2. Put dylibs (e.g. FridaGadget.dylib) that you want to add to the binary in the dylibs_to_insert folder
3. Open the XCode project
4. Set a bundle identifier
5. Select a Signing Team
6. Build the project (Command-B or Product -> Build)

Your resulting modified and resigned binary will be in the build folder.
