#!/bin/sh

# transfer artifacts to ImageJ download server
echo '--> Uploading archives'
scp -pv fiji*.zip fiji*.tar.gz fiji-builds@downloads.imagej.net:upload/ || {
  echo '[ERROR] Failed to upload generated archives.'
  exit 1
}

# move artifacts into the archive structure and update latest link
echo '--> Moving uploaded archives into place'
timestamp=`date "+%Y%m%d-%H%M"`
ssh -v fiji-builds@downloads.imagej.net "
mkdir -p 'archive/$timestamp' &&
mv upload/* 'archive/$timestamp' &&
chmod o+x 'archive/$timestamp' &&
chmod -R o+r 'archive/$timestamp' &&
rm latest && ln -s 'archive/$timestamp' latest
" || {
  echo '[ERROR] Failed to move uploaded archives into place.'
  exit 2
}
