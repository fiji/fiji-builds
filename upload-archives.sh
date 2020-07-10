#!/bin/sh

# transfer artifacts to ImageJ download server
scp -p fiji*.zip fiji*.tar.gz fiji-builds@downloads.imagej.net:upload/ || {
  echo '[ERROR] Failed to upload generated archives.'
  exit 1
}

# move artifacts into the archive structure and update latest link
timestamp=`date "+%Y%m%d-%H%M"`
ssh fiji-builds@downloads.imagej.net "
mkdir -p 'archive/$timestamp' &&
mv upload/* 'archive/$timestamp' &&
rm latest && ln -s 'archive/$timestamp' latest
" || {
  echo '[ERROR] Failed to move uploaded archives into place.'
  exit 2
}
