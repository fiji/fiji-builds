#!/bin/sh

. "${0%/*}/common.include"

# Download portable Fiji distribution as a starting point.
echo "--> Downloading and unpacking $track Fiji as a starting point"
curl -fsO "https://downloads.imagej.net/fiji/$track/$bootstrap.zip" &&
unzip "$bootstrap.zip"
rm "$bootstrap.zip"

# Download the manifests of current JDK/JRE locations.
echo "--> Downloading bundled JDK/JRE manifests"
jdks=$(curl -fs "https://downloads.imagej.net/java/jdk-$track.txt")
jres=$(curl -fs "https://downloads.imagej.net/java/jre-$track.txt")

# Download bundled Java for each platform.
for platform in $platforms
do
  # $java - subfolder of java/ for platform-specific bundled Java.
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
