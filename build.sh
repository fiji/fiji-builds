#!/bin/bash
set -e

echo
echo '== Checking whether anything has changed =='

if [ "$(./fiji-archive-status.sh)" = 'up-to-date' ]; then
  echo 'Nothing has changed. No distros will be generated.'
  exit 0
fi

# Initialize the Fiji.app installation if needed.
if [ ! -d Fiji.app ]
then
  echo
  echo '== Building Fiji installation =='
  ./bootstrap-fiji.sh || exit 1
fi

# Update the Fiji.app installation.
echo
echo '== Updating the Fiji installation =='
./update-fiji.sh Fiji.app || exit 2

# Bundle up the installation for each platform.
echo
echo '== Generating archives =='
./generate-archives.sh Fiji.app || exit 3

# Upload the application bundles.
echo
echo '== Transferring artifacts =='
./upload-archives.sh || exit 4
