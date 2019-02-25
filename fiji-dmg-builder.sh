#!/bin/sh
set -e

test Darwin = "$(uname -s)" || die "This script only runs on MacOSX!"

if [ "$TRAVIS_SECURE_ENV_VARS" != true \
  -o "$TRAVIS_PULL_REQUEST" != false \
  -o "$TRAVIS_BRANCH" != master ]
then
  echo "Skipping non-canonical branch."
  exit
fi

echo "== Configuring environment ==" &&

# Configure SSH. The file .travis/ssh-rsa-key.enc must contain an
# encrypted private RSA key for communicating with the destination server.
mkdir -p "$HOME/.ssh" &&
openssl aes-256-cbc \
  -K "$encrypted_9948786e33bf_key" \
  -iv "$encrypted_9948786e33bf_iv" \
  -in '.travis/ssh-rsa-key.enc' \
  -out "$HOME/.ssh/id_rsa" -d &&
chmod 400 "$HOME/.ssh/id_rsa" &&
ssh-keyscan -H downloads.imagej.net >> "$HOME/.ssh/known_hosts" &&
echo "SSH key installed."


# Make sure that perl and python are available
command -v python > /dev/null || die "python is missing"

echo "== Fetch latest MacOSX tar build from Imagej downloads server =="
curl -s -S https://downloads.imagej.net/fiji/latest/fiji-macosx.tar.gz -o fiji-macosx.tar.gz

echo "== Make a temporary directory and extract the tar into that directory =="
tmp="$(mktemp -d tmp)"
tar -xf fiji-macosx.tar.gz -C tmp

# We use https://pypi.org/project/dmgbuild/ to create the dmg.  This replaces the original perl script which is
# problematic to use with Travis VM due to the Mac::Carbon dependency which has installation issues.
# Besides this is a lot cleaner and easier to maintain.
echo " == Invoke dmgbuild and create dmg =="
dmgbuild -s settings.py "Fiji" fiji-macosx.dmg

echo " == Upload dmg to Imagej downloads server =="
scp -p fiji-macosx.dmg fiji-builds@downloads.imagej.net:fiji-maxosx.dmg.part &&
ssh fiji-builds@downloads.imagej.net "mv -f fiji-maxosx.dmg.part latest/fiji-maxosx.dmg"
