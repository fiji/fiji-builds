#!/bin/sh

. "${0%/*}/common.include"

test -d "$fiji_dir" || {
  echo "[ERROR] Fiji folder '$fiji_dir' does not exist."
  exit 1
}
cd "$fiji_dir"

echo '--> Creating nojre archive'
java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager ../fiji-nojre.zip

for platform in $platforms
do
  echo "--> Generating archive for $platform"

  # HACK: Move aside non-matching platform-specific JARs.
  # The Fiji Packager doesn't understand them yet; see #4.
  cd jars
  mv $platforms ../..
  cd ..
  mv "../$platform" jars/

  java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager \
    --platforms=$platform --jre "$dir/fiji-$platform.zip"

  # HACK: Now put them back. :-)
  mv "jars/$platform" ..
  cd ..
  mv $platforms "$fiji_dir/jars/"
  cd "$fiji_dir"
done
