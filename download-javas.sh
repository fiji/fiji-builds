#!/bin/sh

. "${0%/*}/common.include"

# Download the manifests of current JDK/JRE locations.
echo "--> Downloading bundled JDK/JRE manifests"
jdks=$(curl -fsO "https://downloads.imagej.net/java/jdk-$track.txt")
jres=$(curl -fsO "https://downloads.imagej.net/java/jre-$track.txt")

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
        if [ "$track" = stable -a "$platform" = macosx ]; then
          echo "--> Hacking macosx $jtype to appease the ImageJ launcher"
          # On macOS, the ImageJ launcher expects to find:
          # - java/macosx/<distro>/jre/Contents/Home/lib/jli/libjli.dylib
          # - java/macosx/<distro>/jre/Contents/Home/lib/server/libjvm.dylib
          (
            cd "$targetDir"/*/
            case "$jtype" in
              jre)
                # Within java/macosx/<distro>, the Zulu JRE distro has:
                # - zulu-8.jre/Contents/Home/lib/jli/libjli.dylib
                # - zulu-8.jre/Contents/Home/lib/server/libjvm.dylib
                #
                # So it's almost correct; the jre folder is just named
                # `zulu-8.jre` rather than `jre`. A symlink fixes it.
                ln -s *.jre jre
                ;;
              jdk)
                # Within java/macosx/<distro>, the Zulu JDK distro has:
                # - zulu-8.jdk/Contents/Home/jre/lib/jli/libjli.dylib
                # - zulu-8.jdk/Contents/Home/jre/lib/server/libjvm.dylib
                # - jre -> zulu-8.jdk/Contents/Home/jre
                #
                # and therefore (via the jre symlink):
                # - jre/lib/jli/libjli.dylib
                # - jre/lib/server/libjvm.dylib
                #
                # Consequently, the paths do not match.
                #
                # To fix this, we symlink a nested Contents/Home:
                # - jre/Contents/Home -> jre
                #
                # Yes, it's an infinite directory loop, but the ImageJ
                # Launcher does not recurse infinitely, so it's fine.
                cd jre
                mkdir Contents
                cd Contents
                ln -s .. Home
                ;;
            esac
          )
        fi
      else
        echo "--> Skipping $javaBundle for $platform: no Java bundle URL found"
      fi
    fi
  done
done
