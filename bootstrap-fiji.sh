#!/bin/sh

set -e

FIJI_HOME=$1
test "$FIJI_HOME" || { echo "[ERROR] Please specify folder for Fiji.app." && exit 1; }

launcherVersion=5.0.3
launcherPrefix="https://maven.scijava.org/service/local/artifact/maven/redirect?r=releases&g=net.imagej&a=imagej-launcher&v=$launcherVersion&e="
launcherLinux64="$FIJI_HOME/ImageJ-linux64"
launcherMacOS="$FIJI_HOME/Contents/MacOS/ImageJ-macosx"

mkdir -p "$FIJI_HOME/Contents/MacOS"
mkdir -p "$FIJI_HOME/jars"

# Download ImageJ launcher for all supported platforms.
echo "--> Downloading and installing ImageJ launchers"
curl -fsL "${launcherPrefix}jar" -o "$FIJI_HOME/jars/imagej-launcher-$launcherVersion.jar"
curl -fsL "${launcherPrefix}exe&c=linux64" -o "$launcherLinux64" && chmod +x "$launcherLinux64"
curl -fsL "${launcherPrefix}exe&c=macosx" -o "$launcherMacOS" && chmod +x "$launcherMacOS"
curl -fsL "${launcherPrefix}exe&c=win64" -o "$FIJI_HOME/ImageJ-win64.exe"
curl -fsL "${launcherPrefix}exe&c=win32" -o "$FIJI_HOME/ImageJ-win32.exe"
curl -fsL https://raw.githubusercontent.com/fiji/fiji/master/Contents/Info.plist -o "$FIJI_HOME/Contents/Info.plist"

# Download bundled Java for each platform.
for platform in linux64 win32 win64 macosx
do
  java=$platform
  case "$platform" in
  linux64) java=linux-amd64;;
  esac

  javaDir="$FIJI_HOME/java/$java"
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

# Use scijava-maven-plugin:populate-app goal to populate the JARs.
echo "--> Populating the installation"
rm -rf fiji && git clone git://github.com/fiji/fiji --depth 1
# NB: Suppress "Downloading/Downloaded" messages.
mvn -B -f fiji/pom.xml scijava:populate-app -Dscijava.app.directory="$FIJI_HOME" |
  grep -v '^\[INFO\] Download\(ed\|ing\) from '
