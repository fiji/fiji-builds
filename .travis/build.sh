#!/bin/bash
set -e

if [ "$TRAVIS_SECURE_ENV_VARS" != true \
  -o "$TRAVIS_PULL_REQUEST" != false \
  -o "$TRAVIS_BRANCH" != master ]
then
  echo "Skipping non-canonical branch."
  exit
fi

CACHE_DIR=cache
FIJI_HOME="$CACHE_DIR/Fiji.app"

echo
echo "== Checking whether anything has changed =="

# Get last modified date from header.
repos=( "imagej" "sites" "fiji")
date1=`curl -svX HEAD https://update.imagej.net/db.xml.gz 2>&1 | grep 'Last-Modified:'`
date2=`curl -svX HEAD https://sites.imagej.net/Java-8/db.xml.gz 2>&1 | grep 'Last-Modified:'`
date3=`curl -svX HEAD https://update.fiji.sc/db.xml.gz 2>&1 | grep 'Last-Modified:'`
# Trim string to just the date.
date1="${date1#*, }"
date2="${date2#*, }"
date3="${date3#*, }"
# Convert date to seconds since the epoch (commented code is MacOS version).
#date1=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date1" +%s`
#date2=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date2" +%s`
#date3=`date -j -f '%d %b %Y %H:%M:%S %Z ' "$date3" +%s`
date1=`date --date="$date1" +%s`
date2=`date --date="$date2" +%s`
date3=`date --date="$date3" +%s`
dates=( "$date1" "$date2" "$date3" )

# Read previous dates. The first time, there won't be any.
changes=false
datesFile="$CACHE_DIR/dates.txt"
if [ ! -e "$datesFile" ];
then
  # Save the first dates
  echo "Running for the first time, no dates to compare with, assuming changes exist."
  mkdir -p "$CACHE_DIR"
  changes=true
else
  # Compare to previous cached dates, then save latest dates.
  echo "Comparing entries"
  i=0
  while IFS= read -r line
  do
    echo "Comparing new $line to previous ${dates[$i]}"
    if [[ $line -lt ${dates[$i]} ]];
    then
      echo "There are updates in the ${repos[$i]} site. New distros will be generated."
      changes=true
    fi
    i=$i+1
  done <"$datesFile"
fi

if [ "$changes" = false ]; then
   echo "Nothing has changed. No distros will be generated."
   exit 0
fi

# Initialize the Fiji.app installation if needed.
test -d "$FIJI_HOME" || {
  echo
  echo "== Building Fiji installation =="
  ./bootstrap-fiji.sh "$FIJI_HOME" || exit 1
}

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

# Finally since everything worked OK, save the new dates.
echo "${dates[0]}" > "$datesFile"
echo "${dates[1]}" >> "$datesFile"
echo "${dates[2]}" >> "$datesFile"
