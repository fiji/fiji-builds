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
set +e
if [ -d "$JAVA_HOME" ]; then
  DEBUG=1 "$fiji_dir/$launcher" --java-home "$JAVA_HOME" --update update-force-pristine
else
  DEBUG=1 "$fiji_dir/$launcher" --update update-force-pristine
fi
# HACK: Exit code 18 is emitted on Linux due to INIT_THREADS error:
#   Error: Could not find X11 library, not running XInitThreads.
# But we don't care -- let's keep going in that case.
code=$?
test $code -eq 0 -o $code -eq 18 || exit $code
set -e

echo "--> Removing obsolete files..."

# Remove obsolete fiji launcher wrappers.
rm -rfv \
  "$fiji_dir/Contents/MacOS/fiji-macosx" \
  "$fiji_dir/Contents/MacOS/fiji-tiger" \
  "$fiji_dir/fiji-linux64" \
  "$fiji_dir/fiji-win32.exe" \
  "$fiji_dir/fiji-win64.exe"

# Remove any other obsolete files.
{
  # Backup launcher-related files.
  find "$fiji_dir" -name '*.old'
  find "$fiji_dir" -name '*.old.app'
  find "$fiji_dir" -name '*.old.exe'
  # Dangling empty directories.
  find "$fiji_dir" -type d -empty
} | xargs rm -rfv || true

echo "--> Fixing permissions..."

# Remove rogue executable bit from non-executable JAR files.
find "$fiji_dir" -name '*.jar' -perm /+x -exec chmod -xv "{}" \;

echo "--> Done updating!"
