#!/bin/sh

. "${0%/*}/common.include"

verify_fiji_dir

echo "--> Generating $track portable archive"
if [ -e "$fiji_dir/java" ]; then
  echo "[ERROR] Unexpected $fiji_dir/java folder!"
  exit 1
fi
zip -r9y "fiji-$track-portable-nojava.zip" "$fiji_dir"

move_aside() {
  dir=$1

  mkdir -p "$dir"
  cd "$fiji_dir/$dir"

  # Map long platform name to short platform name.
  for p in $platforms
  case "$p" in
    linux-x64) p=linux64 ;;
    macos-x64) p=macosx ;;
    windows-x64) p=win64 ;;
  esac

  if [ -d "$p" ]; then
    mv "$p" "../../$dir/"
  fi
}

move_aside jars
move_aside lib

for platform in $platforms
do
  echo "--> Generating $track $platform archive"

  # CTR START HERE

  # $java - subfolder of java/ for platform-specific bundled Java.
  case "$track:$platform" in
    stable:linux64) java=linux-amd64 ;;
    *) java=$platform ;;
  esac

  # Move aside non-matching platform-specific files.
  mkdir -p jars lib
  cd "$fiji_dir/jars"
  mv $platforms ../../jars/
  cd ../..
  mv "jars/$platform/" "$fiji_dir/jars/"

  zip -r9y "fiji-$track-$platform-$jdkjre.zip"

  # Now put everything back.
  mv "jars/$platform" ..
  cd ..
  mv $platforms "$fiji_dir/jars/"
  cd "$fiji_dir"
done
