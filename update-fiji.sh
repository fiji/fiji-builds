#!/bin/sh

FIJI_HOME=$1
test "$FIJI_HOME" || { echo '[ERROR] Please specify folder for Fiji.app.' && exit 1; }

case "$(uname -s),$(uname -m)" in
  Linux,x86_64) launcher=ImageJ-linux64 ;;
  Linux,*) launcher=ImageJ-linux32 ;;
  Darwin,*) launcher=Contents/MacOS/ImageJ-macosx ;;
  MING*,*) launcher=ImageJ-win32.exe ;;
  MSYS_NT*,*) launcher=ImageJ-win32.exe ;;
  *) echo '[ERROR] Unknown platform' && exit 2 ;;
esac
DEBUG=1 "$FIJI_HOME/$launcher" --update add-update-site Fiji https://update.fiji.sc/
DEBUG=1 "$FIJI_HOME/$launcher" --update add-update-site Java-8 https://sites.imagej.net/Java-8/
DEBUG=1 "$FIJI_HOME/$launcher" --update update-force-pristine
