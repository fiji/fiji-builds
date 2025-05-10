#!/bin/sh

. "${0%/*}/common.include"

verify_fiji_dir

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
  mkdir -p "$dir"
  for f in "$fiji_dir/$dir/"*/; do
    move_file "$f" "$track-$dir"
  done
  # HACK: Restore non-platform-specific bio-formats folder if present.
  move_file "$track-$dir/bio-formats/" "$fiji_dir/$dir"
}

create_archive() {
  suffix=$1
  archive="fiji-$track-$suffix.zip"
  if [ ! -e "$archive" ]; then
    (set -x; zip -r9yq "$archive" "$fiji_dir")
  else
    echo "Skipping $suffix: archive already exists."
  fi
}

if [ -e "$fiji_dir/java" ]; then
  echo "[ERROR] Unexpected $fiji_dir/java folder!"
  exit 1
fi
notify "Generating $track portable archive"
create_archive portable-nojava

notify "Setting aside platform-specific files"
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
  notify "Staging $platform"

  # Move matching platform-specific files back into place.
  move_file "$track-jars/$platform/" "$fiji_dir/jars"
  move_file "$track-lib/$platform/" "$fiji_dir/lib"
  for launcher in $(launchers "$track" "$platform"); do
    subDir=${launcher%/*}
    srcFile=${launcher##*/}
    test "$launcher" != "$subDir" || subDir=
    move_file "$track-launchers/$srcFile" "$fiji_dir/$subDir"
  done

  # Move matching platform-specific Java bundle into place.
  javaDir=$(java_dir "$track" "$platform")
  for jtype in jdk jre; do 
    notify "Generating $platform $jtype archive"
    # Shuffle in the correct Java bundle before archiving.
    (set -x; mv "$jtype-$track/$javaDir/" "$fiji_dir/java/")
    # Archive the installation!
    create_archive "$platform-$jtype"
    # Remove the Java bundle again.
    (set -x; mv "$fiji_dir/java/$javaDir/" "$jtype-$track/")
  done

  # Remove platform-specific files again.
  notify "Unstaging $platform"
  move_dir_aside jars
  move_dir_aside lib
  for launcher in $(launchers "$track" "$platform"); do
    move_file "$fiji_dir/$launcher" "$track-launchers"
  done
done

# Clean up.
rmdir "$fiji_dir/java/"
