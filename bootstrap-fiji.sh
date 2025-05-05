#!/bin/sh

set -e

# Download Fiji.
echo '--> Downloading and unpacking the latest Fiji as a starting point'
curl -fsO https://downloads.imagej.net/fiji/latest/fiji-nojre.zip &&
unzip fiji-nojre.zip

# NB: Avoid clash with newly packaged archive later.
rm fiji-nojre.zip

# Download bundled Java for each platform.
for platform in linux64 win32 win64 macosx
do
  java=$platform
  case "$platform" in
  linux64) java=linux-amd64;;
  esac

  javaDir="Fiji.app/java/$java"
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
