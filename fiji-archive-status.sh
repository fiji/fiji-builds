#!/bin/bash

# Emits 'up-to-date' if a Fiji app bundle has been created since the most
# recent update to any of the core ImageJ/Fiji update sites, and
# 'update-needed' otherwise

# -- helper methods --

# convert timestamp strings to numeric values for easier comparison
convert_time () {
  datenum=$(date --date="$1" '+%s')
  echo $datenum
}

# get the last modified date of a given url as seconds sinch the epoch
get_modified_date () {
  result=$(curl -Ifs "$1" | grep '^Last-Modified:')
  datestamp=${result#*, }
  dateval=$(convert_time "$datestamp")
  echo $dateval
}

# get the most recent modification date from among the core ImageJ/Fiji update sites
update_site_modified () {
  update_site_times=()
  for repo in \
    update.imagej.net       \
    update.fiji.sc          \
    sites.imagej.net/Java-8
  do
    dateval=$(get_modified_date "https://$repo/db.xml.gz")
    update_site_times+=("$dateval")
  done

  # Just use the most recent modified date from among the update sites
  sorted=($(printf "%s\n" ${update_site_times[@]} | sort -r))

  echo ${sorted[0]}
}

# get the most recent modification date of a selected fiji bundle
fiji_bundle_modified () {
  dateval=$(get_modified_date "https://downloads.imagej.net/fiji/latest/fiji-nojre.zip")
  echo $dateval
}

# -- program entry point --

usm="$(update_site_modified)"

fbm="$(fiji_bundle_modified)"

if [ "$usm" -gt "$fbm" ]; then
  # update needed
  echo "update-needed"
else
  echo "up-to-date"
fi

