#!/bin/sh

. "${0%/*}/common.include"

verify_fiji_dir

echo "--> Generating $track portable archive"
mv "$fiji_dir/java" .
zip -r9y "fiji-$track-portable-nojava.zip" "$fiji_dir"
mv java "$fiji_dir"

for platform in $platforms
do
  echo "--> Generating $track $platform archive"

  # CTR START HERE -- messy...

  # $java - subfolder of java/ for platform-specific bundled Java.
  case "$track:$platform" in
    stable:linux64) java=linux-amd64 ;;
    *) java=$platform ;;
  esac

  # $jarslib - subfolder of jars/ and lib/ for platform-specific files.
  case "$platform" in
    linux-x64) jarslib=linux64 ;;
    macos-x64) jarslib=macosx ;;
    windows-x64) jarslib=win64 ;;
    *) jarslib=$platform ;;
  esac

  # Move aside non-matching platform-specific files.
  cd "$fiji_dir/jars"
  mv $platforms ../..
  cd ../..
  mv "$platform" "$fiji_dir/jars/"

  zip -r9y "fiji-$track-$platform-$jdkjre.zip"

  # Now put everything back.
  mv "jars/$platform" ..
  cd ..
  mv $platforms "$fiji_dir/jars/"
  cd "$fiji_dir"
done
