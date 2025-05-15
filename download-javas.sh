#!/bin/sh

. "${0%/*}/common.include"

# Download the manifests of current JDK/JRE locations.
echo "--> Downloading bundled JDK/JRE manifests"
jdks=$(curl -fs "https://downloads.imagej.net/java/jdk-$track.txt")
jres=$(curl -fs "https://downloads.imagej.net/java/jre-$track.txt")

# Download bundled Java for each platform + bundle type (JDK or JRE).
for platform in $platforms; do
  javaDir="$(java_dir "$track" "$platform")"
  for jtype in jdk jre; do
    javaBundle="$jtype-$track"
    targetDir="$javaBundle/$javaDir"
    if [ -e "$targetDir" ]
    then
      echo "--> Skipping $javaBundle for $platform: $targetDir already exists"
    else
      javaURL=$(grep "^$javaDir=" "$javaBundle.txt" | sed 's/[^=]*=//')
      if [ "$javaURL" ]; then
        echo "--> Downloading and unpacking $javaBundle for $platform"
        mkdir -p "$targetDir"
        (
          cd "$targetDir"
          curl -fsO "$javaURL"
          javaArchive=${javaURL##*/}
          case "$javaURL" in
            *.tar.*) tar xvf "$javaArchive" ;;
            *.zip)   unzip "$javaArchive" ;;
          esac
          rm "$javaArchive"
        )
      else
        echo "--> Skipping $javaBundle for $platform: no Java bundle URL found"
      fi
    fi
  done
done
