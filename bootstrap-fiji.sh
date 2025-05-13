#!/bin/sh

. "${0%/*}/common.include"

# Download portable Fiji distribution as a starting point.
echo "--> Downloading and unpacking $track Fiji as a starting point"
curl -fO "https://downloads.imagej.net/fiji/$track/$fiji_nojava.zip"
unzip "$fiji_nojava.zip"
rm "$fiji_nojava.zip"
