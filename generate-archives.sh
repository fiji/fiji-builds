#!/bin/sh

dir=$(cd "$(dirname "$0")" && pwd)
FIJI_HOME=$1
test -d "$FIJI_HOME" || { echo "[ERROR] Please specify folder for Fiji.app." && exit 1; }
cd "$FIJI_HOME"

set -e

echo "--> Creating nojre archive"
java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager "$dir/fiji-nojre.zip"

for platform in linux64 win32 win64 macosx
do
  echo "--> Generating archive for $platform"

  # HACK: Move aside non-matching platform-specific JARs.
  # The Fiji Packager doesn't understand them yet; see #4.
  mv jars/linux32 jars/linux64 jars/win32 jars/win64 jars/macosx ..
  mv "../$platform" jars/

  java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager \
    --platforms=$platform --jre "$dir/fiji-$platform.zip"

  # HACK: Now put them back. :-)
  mv "jars/$platform" ..
  mv ../linux32 ../linux64 ../win32 ../win64 ../macosx jars/
done
