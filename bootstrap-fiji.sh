#!/bin/sh

. "${0%/*}/common.include"

# Download Fiji.
echo "--> Downloading and unpacking $track Fiji as a starting point"
curl -fsO "https://downloads.imagej.net/fiji/$track/fiji-nojre.zip" &&
unzip fiji-nojre.zip

# NB: Avoid clash with newly packaged archive later.
rm fiji-nojre.zip

# CTR START HERE:
# Get JDK locations from downloads.imagej.net/java manifests.
jdks=$(curl -fs "https://downloads.imagej.net/java/jdk-$track.txt")

# For latest track, rename fiji-nojre to fiji-all-platforms.
# Easiest way to let Jaunch download Java? Ship Python and use cjdk! :D

# Download bundled Java for each platform.
for platform in $platforms
do
  case "$track:$platform" in
    stable:linux64) java=linux-amd64 ;;
    *) java=$platform ;;
  esac

  javaDir="$fiji_dir/java/$java"
  if [ -d "$javaDir" ]
  then
    echo "--> Skipping Java for $platform: $javaDir already exists"
  else
    echo "--> Downloading and installing bundled Java for $platform"
    mkdir -p "$javaDir" && (
      cd "$javaDir" &&
      curl -fsO https://downloads.imagej.net/java/$java.tar.gz &&
      tar -zxvf $java.tar.gz &&
      rm $java.tar.gz
    )
  fi
done
