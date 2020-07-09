#!/bin/bash
set -e

if [ "$TRAVIS_SECURE_ENV_VARS" != true \
  -o "$TRAVIS_PULL_REQUEST" != false \
  -o "$TRAVIS_BRANCH" != master ]
then
  echo "Skipping non-canonical branch."
  exit
fi

CACHE_DIR=cache
FIJI_HOME="$CACHE_DIR/Fiji.app"

echo
echo "== Constructing Fiji installations =="

# Get last modified date from header
repos=( "imagej" "sites" "fiji")
date1=`curl -svX HEAD https://update.imagej.net/db.xml.gz 2>&1 | grep 'Last-Modified:'`
date2=`curl -svX HEAD https://sites.imagej.net/Java-8/db.xml.gz 2>&1 | grep 'Last-Modified:'`
date3=`curl -svX HEAD https://update.fiji.sc/db.xml.gz 2>&1 | grep 'Last-Modified:'`
# Trim string to just the date
date1="${date1#*, }"
date2="${date2#*, }"
date3="${date3#*, }"
# Convert date to seconds since the epoch, commented code is MacOS version
#date1=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date1" +%s`
#date2=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date2" +%s`
#date3=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date3" +%s`
date1=`date --date="$date1" +%s`
date2=`date --date="$date2" +%s`
date3=`date --date="$date3" +%s`
dates=( "$date1" "$date2" "$date3" )

# Read previous dates. The first time there wont be any
changes=false
datesFile="$CACHE_DIR/dates.txt"
if [ ! -e "$datesFile" ];
then
  # Save the first dates
  echo "Running for the first time, not dates to compare with, assuming changes exist"
  mkdir -p "$CACHE_DIR"
  changes=true
else
  # Compare to previous cached dates, then save latest dates
  echo "Comparing entries"
  i=0
  while IFS= read -r line
  do
    echo "Comparing new $line to previous ${dates[$i]}"
	  if [[ $line -lt ${dates[$i]} ]];
    then
      echo "There are updates in the ${repos[$i]} site, new distros will be generated"
      changes=true
    fi
    i=$i+1
  done <"$datesFile"
fi

if [ "$changes" = false ]; then
   echo "Nothing has changed, no distros will be generated"
   exit 0
fi
# bootstrap with Java-8 update site enabled
curl -o bootstrap.js https://downloads.imagej.net/bootstrapJ8.js

test -d "$FIJI_HOME" || mkdir "$FIJI_HOME"

# make sure all platforms are active
for LAUNCHER in \
  ImageJ-linux32 ImageJ-linux64 \
  ImageJ-win32.exe ImageJ-win64.exe \
  Contents/MacOS/ImageJ-macosx Contents/MacOS/ImageJ-tiger \
  fiji-linux fiji-linux64 \
  fiji-win32.exe fiji-win64.exe \
  Contents/MacOS/fiji-macosx Contents/MacOS/fiji-tiger
do
  mkdir -p "$FIJI_HOME/$(dirname "$LAUNCHER")" &&
  touch "$FIJI_HOME/$LAUNCHER"
done

# get MacOSX-specific file
mkdir -p "$FIJI_HOME"/Contents &&
curl https://raw.githubusercontent.com/fiji/fiji/master/Contents/Info.plist > "$FIJI_HOME"/Contents/Info.plist

date > .timestamp

# this is the real update
(cd "$FIJI_HOME" &&
echo "== Performing first update ==" &&
DEBUG=1 jrunscript ../bootstrap.js update-force-pristine &&
# CTR HACK: Run the update a 2nd time, "just in case." In practice, this does
# change the state of the installation, pulling in a newer Contents/Info.plist.
# While I do not understand why, the long-term plan is to ditch Updater-based
# bootstrapping anyway, so I'm not going to dig more deeply into it.
# See also this Image.sc Forum thread:
# https://forum.image.sc/t/java-6-required-on-mac-install-fiji/23093/15
echo "== Performing second update ==" &&
DEBUG=1 jrunscript ../bootstrap.js update-force-pristine &&

echo "== Creating nojre archives =="
find -type f -newer ../.timestamp > ../updated.txt &&
for p in fiji-nojre.tar.gz fiji-nojre.zip
do
  java -Dij.dir=. -classpath plugins/\*:jars/\* fiji.packaging.Packager ../$p
done &&

# download bundled Java for this platform
for platform in linux32 linux64 win32 win64 macosx
do
  java=$platform
  case "$platform" in
  linux32) java=linux;;
  linux64) java=linux-amd64;;
  esac

  test -d java/$java || {
		echo "== Downloading bundled Java for $platform =="
		mkdir -p java/$java &&
    cd java/$java &&
    curl -fsO https://downloads.imagej.net/java/$java.tar.gz &&
    tar -zxvf $java.tar.gz &&
    rm $java.tar.gz &&
    jre=$(find . -maxdepth 1 -name 'jre*') &&
    jdk=$(echo "$jre" | sed 's/jre/jdk/') &&
    if [ "$jdk" ]; then mkdir "$jdk" && mv "$jre" "$jdk/jre"; fi
  }

  echo "== Generating Fiji archives for $platform =="
  for ext in zip tar.gz
  do
    java -Dij.dir=. -classpath plugins/\*:jars/\* fiji.packaging.Packager \
      --platforms=$platform --jre ../fiji-$platform.$ext
  done
done)

gzip -d < fiji-nojre.tar.gz | bzip2 -9 > fiji-nojre.tar.bz2

echo
echo "== Transferring artifacts =="

# transfer artifacts to ImageJ download server
scp -p fiji*.zip fiji*.tar.gz fiji-builds@downloads.imagej.net:upload/ || {
	echo '[ERROR] Failed to upload generated archives.'
	exit 1
}

# move artifacts into the archive structure and update latest link
timestamp=`date "+%Y%m%d-%H%M"`
ssh fiji-builds@downloads.imagej.net "
mkdir -p 'archive/$timestamp' &&
mv upload/* 'archive/$timestamp' &&
rm latest && ln -s 'archive/$timestamp' latest
" || {
	echo '[ERROR] Failed to move uploaded archives into place.'
	exit 1
}

# Finally since everything worked OK save the new dates
echo "${dates[0]}" > "$datesFile"
echo "${dates[1]}" >> "$datesFile"
echo "${dates[2]}" >> "$datesFile"
