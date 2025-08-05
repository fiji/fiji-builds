#!/bin/sh

. "${0%/*}/common.include"

# Glean the current platform.

os=$(uname)
case "$(uname)" in
  MING*|MSYS*) os=windows ; launcher=fiji.bat ;;
  Darwin)      os=macos   ; launcher=fiji     ;;
  Linux)       os=linux   ; launcher=fiji     ;;
  *) die "Unsupported platform: $(uname)"
esac

arch=$(uname -m)
case "$arch" in
  aarch64)      arch=arm64 ;;
  amd64|x86_64) arch=x64   ;;
esac

# Use JDK matching the current track.
java_base="jdk-$track/$(java_dir "$track" "$os-$arch")"
java_home=$(find "$java_base" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [ -d "$java_home" ]
then
  export JAVA_HOME=$java_home
  echo "--> Using JAVA_HOME $JAVA_HOME"
else
  >&2 echo "[WARNING] No Java found beneath $java_base; relying on system Java."
fi

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
find . -name '*.old.app' -exec rm -rf "{}" \; || true
find . -name '*.old.exe' -exec rm -rf "{}" \;

# Remove rogue executable bit from non-executable JAR files.
find . -name '*.jar' -exec chmod -x "{}" \;
