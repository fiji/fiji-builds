#!/bin/sh

FIJI_HOME=$1
test -d "$FIJI_HOME" || { echo "[ERROR] Please specify folder for Fiji.app." && exit 1; }
cd "$FIJI_HOME"

echo "--> Creating nojre archives"
for p in fiji-nojre.tar.gz fiji-nojre.zip
do
  java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager ~/$p
done &&

for platform in linux64 win32 win64 macosx
do
  echo "--> Generating Fiji archives for $platform"
  for ext in zip tar.gz
  do
    java -Dij.dir=. -classpath 'plugins/*:jars/*' fiji.packaging.Packager \
      --platforms=$platform --jre ~/fiji-$platform.$ext
  done
done
