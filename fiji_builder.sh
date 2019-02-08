#!/bin/bash
# Get last modified date from header
repos=( "imagej" "sites" "fiji")
date1=`curl -svX HEAD https://update.imagej.net/db.xml.gz 2>&1 | grep 'Last-Modified:'`
date2=`curl -svX HEAD https://sites.imagej.net/Java-8/db.xml.gz 2>&1 | grep 'Last-Modified:'`
date3=`curl -svX HEAD https://update.fiji.sc/db.xml.gz 2>&1 | grep 'Last-Modified:'`
# Trim string to just the date
date1="${date1#*, }"
date2="${date2#*, }"
date3="${date3#*, }"
# Convert date to seconds since the epoc, commented code is MacOS version
#date1=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date1" +%s`
#date2=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date2" +%s`
#date3=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date3" +%s`
date1=`date --date="$date1" +%s`
date2=`date --date="$date2" +%s`
date3=`date --date="$date3" +%s`
dates=( "$date1" "$date2" "$date3" )

# Read previous dates. The first time there wont be any
changes=false
if [ ! -e dates.txt ];
then 
  # Save the first dates
  echo "Running for the first time, not dates to compare with, assuming changes exist"
  echo "${dates[0]}" > dates.txt
  echo "${dates[1]}" >> dates.txt
  echo "${dates[2]}" >> dates.txt
  changes=true
else
  # Compare to previous cached dates, then save latest dates
  echo "Comparing entries"
  file="dates.txt"
  i=0
  while IFS= read -r line
  do
    echo "$line"
    echo "${dates[$i]}"
	  if [[ $line -lt ${dates[$i]} ]]; 
    then
      echo "There are updates in the ${repos[$i]} site, new distros will be generated"
      changes=true
    fi
    i=$i+1
  done <"$file"

  # Save the new  dates
  echo "${dates[0]}" > dates.txt
  echo "${dates[1]}" >> dates.txt
  echo "${dates[2]}" >> dates.txt
fi

if [ "$changes" = false ]; then
   echo "Nothing has changed, no distros will be generated"
   exit 0
fi
# bootstrap with Java-8 update site enabled
curl -o bootstrap.js https://downloads.imagej.net/bootstrapJ8.js

test -d Fiji.app || mkdir Fiji.app

# make sure all platforms are active
for LAUNCHER in \
  ImageJ-linux32 ImageJ-linux64 \
  ImageJ-win32.exe ImageJ-win64.exe \
  Contents/MacOS/ImageJ-macosx Contents/MacOS/ImageJ-tiger \
  fiji-linux fiji-linux64 \
  fiji-win32.exe fiji-win64.exe \
  Contents/MacOS/fiji-macosx Contents/MacOS/fiji-tiger
do
  mkdir -p Fiji.app/$(dirname $LAUNCHER) &&
  touch Fiji.app/$LAUNCHER
done

# get MacOSX-specific file
mkdir -p Fiji.app/Contents &&
curl https://raw.githubusercontent.com/fiji/fiji/master/Contents/Info.plist > Fiji.app/Contents/Info.plist

date > .timestamp

# this is the real update
(cd Fiji.app &&
jrunscript ../bootstrap.js update-force-pristine &&

echo "Creating nojre archives"
find -type f -newer ../.timestamp > ../updated.txt &&
for p in fiji-nojre.tar.gz fiji-nojre.zip
do
  java -Dij.dir=. -classpath plugins/\*:jars/\* fiji.packaging.Packager ../$p
done &&

echo "Download bundled jre for platform"
# download bundled JRE for this platform
for platform in linux32 linux64 win32 win64 macosx
do
  java=$platform
  case "$platform" in
  linux32) java=linux;;
  linux64) java=linux-amd64;;
  esac

  test -d java/$java || (mkdir -p java/$java &&
  	cd java/$java &&
    wget -r -nH -np -nd http://downloads.imagej.net/java/$java.tar.gz &&
    tar -zxvf $java.tar.gz &&
    rm $java.tar.gz &&
    jre=$(find . -maxdepth 1 -name 'jre*') &&
    jdk=$(echo "$jre" | sed 's/jre/jdk/') &&
    mkdir "$jdk" && mv "$jre" "$jdk/jre"
  )

 echo "Package jre"
  for ext in zip tar.gz
  do
    java -Dij.dir=. -classpath plugins/\*:jars/\* fiji.packaging.Packager \
      --platforms=$platform --jre ../fiji-$platform.$ext
  done
done)

gzip -d < fiji-nojre.tar.gz | bzip2 -9 > fiji-nojre.tar.bz2

# transfer artifacts to ImageJ download server
for f in fiji*.zip fiji*.tar.gz
do
  scp -p "$f" downloads.imagej.net:"$f.part" &&
  ssh downloads.imagej.net "mv -f \"$f.part\" \"fiji-latest/$f\""
done
