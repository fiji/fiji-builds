#!/bin/sh

. "${0%/*}/common.include"

case "$(uname)" in
  MING*|MSYS*) launcher=fiji.bat ;;
  *) launcher=fiji ;;
esac

DEBUG=1 "$fiji_dir/$launcher" --update update-force-pristine
# CHECK - are fiji and fiji.bat still present afterward?
