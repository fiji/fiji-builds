#!/bin/sh
set -e

tmpl_dir="/app/fiji"
mut_userdir="/var/data"

if [ ! -f "$mut_userdir/ImageJ-linux64" ]; then
  echo "Copying Fiji to mutable, user-owned directory..."
  cp -dr --preserve=mode $tmpl_dir/* $mut_userdir/
  rm $mut_userdir/launch-fiji.sh
fi

exec $mut_userdir/ImageJ-linux64 --system $@
