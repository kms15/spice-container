#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2021 Kendrick Shaw

set -e
set -x

# Open a new container
container=$(buildah from debian:11)

# Install Xspice, openbox, Firefox, xrandr, and xterm
buildah config --env DEBIAN_FRONTEND=noninteractive $container
buildah run $container apt-get --quiet --assume-yes update
buildah run $container apt-get --quiet --assume-yes install xserver-xspice openbox firefox-esr x11-xserver-utils xterm
buildah config --env DEBIAN_FRONTEND= $container

# Workaround for bug in Xspice caused by new check to make sure the user passed
# at least arg0 in python 3.6+ (see
# https://www.mail-archive.com/spice-devel@lists.freedesktop.org/msg51868.html)
buildah run $container sed -i \
    "s/os.spawnlpe(os.P_NOWAIT, args.xsession, environ)/os.spawnlpe(os.P_NOWAIT, args.xsession, args.xsession, environ)/g" \
    /usr/bin/Xspice

# Workaround to start X as a non-root user without a physical screen
echo "allowed_users=anybody" | buildah run $container tee --append /etc/X11/Xwrapper.config

# Some command line parameters to Xspice don't seem to be working properly as a
# non-root user, so we'll set them in the config file.
buildah run $container sed -i \
    's/#Option "SpiceDisableTicketing" "False"/Option "SpiceDisableTicketing" "True"/g' \
    /etc/X11/spiceqxl.xorg.conf

# make a user-level account so we don't have to run as root in the container
buildah run $container useradd app
buildah run $container mkdir -p /home/app/.config/openbox/autostart.d
buildah run $container chown -R app:app /home/app
buildah config --user app:app $container
buildah config --workingdir /home/app $container

# start firefox by default
buildah run $container ln -s /usr/bin/firefox /home/app/.config/openbox/autostart.d/

# configure and write the container
buildah config --port 5900 $container
buildah config --entrypoint "/usr/bin/Xspice --xsession openbox-session :1" $container
buildah config --label maintainer="Kendrick Shaw <kms15@case.edu>" $container
buildah commit --format docker $container spice-container:latest
