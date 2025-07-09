#!/bin/sh

set -e

for track in latest stable; do

echo
echo '/-----------------\'
echo "| BUILDING $track |"
echo '\-----------------/'

echo
echo '== Checking whether anything has changed =='

if [ "$(./fiji-archive-status.sh "$track")" = 'up-to-date' ]; then
  echo 'Nothing has changed. No distros will be generated.'
  continue
fi

# Initialize the Fiji installation if needed.
if [ ! -d "$fiji_dir" ]; then
  echo
  echo '== Building Fiji installation =='
  ./bootstrap-fiji.sh "$track" || exit 1
fi

# Download the Java bundles.
echo
echo '== Downloading Java bundles =='
./download-javas.sh "$track" || exit 2

# Update the Fiji installation.
echo
echo '== Updating the Fiji installation =='
./update-fiji.sh "$track" || exit 3

# Bundle up the installation for each platform.
echo
echo '== Generating archives =='
./generate-archives.sh "$track" || exit 4

# Upload the application bundles.
echo
echo '== Transferring artifacts =='
./upload-archives.sh "$track" || exit 5

done
