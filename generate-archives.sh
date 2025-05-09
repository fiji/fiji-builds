#!/bin/sh

. "${0%/*}/common.include"

verify_fiji_dir

echo "--> Generating $track portable archive"
if [ -e "$fiji_dir/java" ]; then
  echo "[ERROR] Unexpected $fiji_dir/java folder!"
  exit 1
fi
zip -r9y "fiji-$track-portable-nojava.zip" "$fiji_dir"

move_file() {
  src_file=$1
  dest_dir=$2
  if [ -e "$src_file" ]; then
    mkdir -p "$dest_dir"
    mv "$src_file" "$dest_dir/"
  fi
}

move_dir_aside() {
  dir=$1
  mkdir -p "$dir"
  mv "$fiji_dir/$dir/"*/ "$dir/"
  # HACK: Restore non-platform-specific bio-formats folder if present.
  test ! -e "$dir/bio-formats" || mv "$dir/bio-formats" "$fiji_dir/$dir/"
}

move_dir_into_place() {
  platform=$1
  dir=$2
  mv "$dir/$platform/" "$fiji_dir/$dir/"
}

mkdir -p "$fiji_dir/java"
for platform in $platforms
do
  echo "--> Generating $track $platform archive"

  move_dir_aside jars
  move_dir_aside lib
  move_dir_into_place "$platform" jars/
  move_dir_into_place "$platform" lib

  # Move aside launchers for all platforms.
  for launcher in "$fiji_dir/Contents" "$fiji_dir/Fiji.app" "$fiji_dir"/ImageJ-* "$fiji_dir"/fiji-*; do
    move_file "$launcher" $track-launchers
  done
  # CTR START HERE - also cover config/jaunch/jaunch-*
  # Move correct platform launchers back into place.
  for launcher in $(launchers "$track" "$platform"); do
    mv "$track-launchers/$launcher" "$fiji_dir/"
  done

  javaDir=$(java_dir "$track" "$platform")
  for jtype in jdk jre; do 
    # Shuffle in the correct Java bundle before archiving.
    mv "$jtype-$track/$platform/" "$fiji_dir/java/$javaDir"
    zip -r9y "fiji-$track-$platform-$jtype.zip"
    mv "$fiji_dir/java/$javaDir/" "$jtype-$track/$platform"
  done
done

move_aside jars
move_aside lib
rmdir "$fiji_dir/java/"
