#!/bin/sh

. "${0%/*}/common.include"

verify_fiji_dir

echo "--> Generating $track portable archive"
if [ -e "$fiji_dir/java" ]; then
  echo "[ERROR] Unexpected $fiji_dir/java folder!"
  exit 1
fi
(set -x; zip -r9yq "fiji-$track-portable-nojava.zip" "$fiji_dir")

move_file() {
  src_file=$1
  dest_dir=$2
  if [ -e "$src_file" ]; then
    mkdir -p "$dest_dir"
    (set -x; mv "$src_file" "$dest_dir/")
  fi
}

move_dir_aside() {
  dir=$1
  echo "+ move_dir_aside '$dir'"
  mkdir -p "$dir"
  move_file "$fiji_dir/$dir/"*/ "$track-$dir"
  # HACK: Restore non-platform-specific bio-formats folder if present.
  move_file "$track-$dir/bio-formats/" "$fiji_dir/$dir"
}

# Move all platform-specific files aside.
move_dir_aside jars
move_dir_aside lib
for launcher in \
  "$fiji_dir/Contents" "$fiji_dir/Fiji.app" \
  "$fiji_dir"/ImageJ-* "$fiji_dir"/fiji-* \
  "$fiji_dir"/config/jaunch/jaunch-*
do
  move_file "$launcher" "$track-launchers"
done

mkdir -p "$fiji_dir/java"

for platform in $platforms; do
  echo "--> Generating $track $platform archive"

  # Move matching platform-specific files back into place.
  move_file "$track-jars/$platform/" "$fiji_dir/jars"
  move_file "$track-lib/$platform/" "$fiji_dir/lib"
  for launcher in $(launchers "$track" "$platform"); do
    subDir=${launcher%/*}
    test "$launcher" != "$subDir" || subDir=
    (set -x; mv "$track-launchers/$launcher" "$fiji_dir/$subDir")
  done

  # Move matching platform-specific Java bundle into place.
  javaDir=$(java_dir "$track" "$platform")
  for jtype in jdk jre; do 
    # Shuffle in the correct Java bundle before archiving.
    (set -x; mv "$jtype-$track/$platform/" "$fiji_dir/java/$javaDir")
    # Archive the installation!
    (set -x; zip -r9yq "fiji-$track-$platform-$jtype.zip")
    # Remove the Java bundle again.
    (set -x; mv "$fiji_dir/java/$javaDir/" "$jtype-$track/$platform")
  done

  # Remove platform-specific files again.
  move_dir_aside jars
  move_dir_aside lib
  for launcher in $(launchers "$track" "$platform"); do
    (set -x; mv "$fiji_dir/$launcher" "$track-launchers/")
  done
done

# Clean up.
rmdir "$fiji_dir/java/"
