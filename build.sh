#!/bin/bash
set -e

FIJI_HOME="Fiji.app"

echo
echo "== Checking whether anything has changed =="

up_to_date="$(./fiji-archive-status.sh)"

if [ "$up_to_date" = "up-to-date" ]; then
	echo "Nothing has changed. No distros will be generated."
	exit 0
fi

# Initialize the Fiji.app installation if needed.
if [ ! -d "$FIJI_HOME" ]
then
  echo
  echo "== Building Fiji installation =="
  ./bootstrap-fiji.sh "$FIJI_HOME" || exit 1
fi

# Update the Fiji.app installation.
echo
echo "== Updating the Fiji installation =="
./update-fiji.sh "$FIJI_HOME" || exit 2

# Bundle up the installation for each platform.
echo
echo "== Generating archives =="
./generate-archives.sh "$FIJI_HOME" || exit 3

# Upload the application bundles.
echo
echo "== Transferring artifacts =="
./upload-archives.sh || exit 4
