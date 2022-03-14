#
# Docker file for building Flatpak bundles
#
FROM debian:testing

# prepare
RUN apt-get update -qq
RUN apt-get install -yq eatmydata

# install
RUN DEBIAN_FRONTEND=noninteractive eatmydata apt-get install -yq \
    ca-certificates \
    build-essential \
    git \
    flatpak \
    flatpak-builder
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# finish
RUN mkdir /build
WORKDIR /build
