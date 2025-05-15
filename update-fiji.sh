#!/bin/sh

. "${0%/*}/common.include"

case "$(uname)" in
  MING*|MSYS*) launcher=fiji.bat ;;
  *) launcher=fiji ;;
esac

# Invoke the command-line Updater.
if [ -d "$JAVA_HOME" ]; then
  DEBUG=1 "$fiji_dir/$launcher" --java-home "$JAVA_HOME" --update update-force-pristine
else
  DEBUG=1 "$fiji_dir/$launcher" --update update-force-pristine
fi

# Remove obsolete fiji launcher wrappers.
rm -rf \
  "$fiji_dir/Contents/MacOS/fiji-macosx" \
  "$fiji_dir/Contents/MacOS/fiji-tiger" \
  "$fiji_dir/fiji-linux64" \
  "$fiji_dir/fiji-win32.exe" \
  "$fiji_dir/fiji-win64.exe"

# Remove any backup launcher-related files.
find . -name '*.old' -exec rm -rf "{}" \;
find . -name '*.old.exe' -exec rm -rf "{}" \;
