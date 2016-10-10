
# Setup some path variables
TEMP_PATH="${SRCROOT}/resign/tmp"
EXTRACTED_IPA_PATH="$TEMP_PATH/EXTRACTED_IPA"

IPA_TO_RESIGN_DIR="${SRCROOT}/resign/ipa_to_resign"
DYLIBS_TO_INSERT_DIR="${SRCROOT}/resign/dylibs_to_insert"

# Create directories
rm -rf "$TEMP_PATH" || true
mkdir -p "$TEMP_PATH" || true


# Finding IPA to modify
if [ $(ls -1 $IPA_TO_RESIGN_DIR/*.ipa | wc -l) -gt 1 ]
then
echo "Please ensure that there is only 1 IPA in the folder"
exit
fi

# The .ipa file to resign
IPA_TO_RESIGN=$(ls $IPA_TO_RESIGN_DIR/*.ipa)


# Extract IPA
echo "Extracting IPA"
ditto -xk "$IPA_TO_RESIGN" "$EXTRACTED_IPA_PATH"

# .app path
APP_PATH=$(set -- "$EXTRACTED_IPA_PATH/Payload/"*.app; echo "$1")
echo "App Path: $APP_PATH"


APP_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$APP_PATH/Info.plist")
APP_EXECUTABLE_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$APP_EXECUTABLE"


# Copy App contents
echo "Copying App Contents"
rm -rf "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app" || true
mkdir -p "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app" || true
cp -rf "$APP_PATH/" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/"
cp -rf "$DYLIBS_TO_INSERT_DIR/" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/"


if [ $(ls -1 $DYLIBS_TO_INSERT_DIR/* 2>/dev/null | wc -l) -gt 0 ]
then
	# Insert DYLIBS
	echo "Inserting LOAD commands for DYLIBs"
	for DYLIB in "$DYLIBS_TO_INSERT_DIR/"*
	do
	FILENAME=$(basename $DYLIB)
	"${SRCROOT}/resign/scripts/optool" install -c load -p "@executable_path/$FILENAME" -t "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$APP_EXECUTABLE"
	done

	# Sign DYLIBs
	echo "Sign DYLIBs"
	for DYLIB in "$DYLIBS_TO_INSERT_DIR/"*
	do
	FILENAME=$(basename $DYLIB)
	echo "SIGNING: $FILENAME"
	/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$FILENAME"
	done
fi


# Get Entitlements
TEMP_PLIST="$TEMP_PATH/temp.plist"
REAL_CODE_SIGN_ENTITLEMENTS="$TEMP_PATH/app.entitlements"
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/"$EXPANDED_PROVISIONING_PROFILE.mobileprovision" -o "$TEMP_PLIST"
/usr/libexec/PlistBuddy -c "Print Entitlements" "$TEMP_PLIST" -x > "$REAL_CODE_SIGN_ENTITLEMENTS"




# Sign and Entitle the Binary
echo "CodeSign: $BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$APP_EXECUTABLE with Identity: $EXPANDED_CODE_SIGN_IDENTITY Entitlements: $REAL_CODE_SIGN_ENTITLEMENTS"

/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$APP_EXECUTABLE"


rm -rf "$TEMP_PATH" || true


