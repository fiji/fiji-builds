#!/bin/sh

dir=$(cd "$(dirname "$0")" && pwd)
FIJI_HOME=$1
test -d "$FIJI_HOME" || { echo "[ERROR] Please specify folder for Fiji.app." && exit 1; }
cd "$FIJI_HOME"

echo "--> Creating nojre archives"
for p in fiji-nojre.tar.gz fiji-nojre.zip
do
  java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager "$dir/$p"
done &&

for platform in linux64 win32 win64 macosx
do
  echo "--> Generating Fiji archives for $platform"

  # HACK: Move aside non-matching platform-specific JARs.
  # The Fiji Packager doesn't understand them yet; see #4.
  mv \
    "$FIJI_HOME/jars/linux32" \
    "$FIJI_HOME/jars/linux64" \
    "$FIJI_HOME/jars/win32" \
    "$FIJI_HOME/jars/win64" \
    "$FIJI_HOME/jars/macosx" \
    .
  mv "$platform" "$FIJI_HOME/jars/"

  for ext in zip tar.gz
  do
    java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager \
      --platforms=$platform --jre "$dir/fiji-$platform.$ext"
  done

  # HACK: Now put them back. :-)
  mv "$FIJI_HOME/jars/$platform" .
  mv linux32 linux64 win32 win64 macosx "$FIJI_HOME/jars/"
done
