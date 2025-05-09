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
  mv "$fiji_dir/$dir/"*/ "$dir/"
  # HACK: Restore non-platform-specific bio-formats folder if present.
  test ! -e "$dir/bio-formats" || mv "$dir/bio-formats" "$fiji_dir/$dir/"
}

move_into_place() {
  platform=$1
  dir=$2
  mv "$dir/$platform/" "$fiji_dir/$dir/"
}

mkdir -p "$fiji_dir/java"
for platform in $platforms
do
  echo "--> Generating $track $platform archive"

  move_aside jars
  move_aside lib
  move_into_place "$platform" jars
  move_into_place "$platform" lib

  # CTR START HERE - also handle all the launchers, old and new.
  # move_aside launchers
  # move_into_place "$platform" launchers

  for jtype in jdk jre; do 
    # Move correct JDK/JRE into place.
    mv "$jtype-$track/$platform/" "$fiji_dir/java/"
    zip -r9y "fiji-$track-$platform-$jtype.zip"
    # Now shuffle the JDK/JRE back out again.
    mv "$fiji_dir/java/$platform/" "$jtype-$track/"
  done
done

move_aside jars
move_aside lib
rmdir "$fiji_dir/java/"
