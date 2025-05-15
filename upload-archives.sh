#!/bin/sh

. "${0%/*}/common.include"

test "$WEBDAV_USER" -a "$WEBDAV_PASS" || {
  echo '[ERROR] No WebDAV credentials in environment. Skipping upload.'
  exit 2
}

upload() {
  curl -s -A fiji-builds \
    -u "$WEBDAV_USER:$WEBDAV_PASS" \
    -w 'Response code %{http_code}.' \
    -T "$1" https://downloads.imagej.net/incoming/"$1"
}

# Upload files to downloads.imagej.net.
echo "--> Uploading $track archives"
for f in fiji-"$track"-*.zip
do
  echo "$f"
  response=$(upload "$f") && echo "$response" | grep -q 'Response code 201\.' || {
    echo "[ERROR] Upload of '$f' failed:\n$response"
    exit 1
  }
done

# Mark the upload as complete.
echo '--> Marking upload complete'
date > fiji-"$track"-uploaded.txt
upload fiji-"$track"-uploaded.txt >/dev/null
