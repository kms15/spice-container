# Spice Container

This is a simple example of running a virtual desktop inside of a container and
sharing that desktop via
[Spice](https://fedoraproject.org/wiki/Features/Spice). My use-case is running
a closed source application that does not allow the font size to be adjusted on
a machine with a high resolution screen (by using the spice client to provide
magnification), but it also could be used for things like providing a shared
desktop on a remote server or exposing a legacy GUI application inside of a
web-based application using an html5 spice client.

## Prerequisites

The container is built using [buildah](https://buildah.io/) and run using the
OCI-compatible container environment of your choice (e.g.
[podman](https://podman.io/)). You will also probably want a Spice client to
connect to the desktop, for example
[remote-viewer](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-graphic_user_interface_tools_for_guest_virtual_machine_management-remote_viewer).
You can install these three packages on a modern Debian or Ubuntu system using
apt:

    sudo apt install buildah podman virt-viewer

## Building and running the container

The container can be built by running the [`./build.sh`](./build.sh) script:

    ./build.sh

You can then run the container:

    podman container run --detach --name spice-container --publish 127.0.0.1:5910:5900 localhost/spice-container:latest

Then connect to it with a spice client:

    remote-viewer spice://localhost:5910

## Security considerations:

This container does not provide any password protection or encryption for the
connection to the remote desktop. This means that anyone who can access the
network port has complete control of the containerized desktop. The example
podman command above thus only exposes the port on localhost, which is
relatively safe on a single-user machine but not on a machine that you share
with others that you wouldn't trust alone with your desktop. Similarly you
should not expose the port to the outside network, e.g. using `--publish
5900:5900` as everyone on the network would then have full access to the
containerized desktop. One easy way to access this container remotely would be
using ssh tunneling, e.g. by starting the container on your server
`myserver.example.org` as above, running

    ssh -n -f -L localhost:5910:localhost:5910 me@myserver.example.org

on your laptop to set up the ssh tunnel from port 5910 on the laptop to 5910 on
the server, and then running remote-viewer on the laptop as described for the
single machine example.

## Similar projects

For a ready-to-run example that uses Fedora and docker compose, you may want to
look at [Muayyad-Alsadi's
example](https://github.com/muayyad-alsadi/containerized-xorg-spice) (which was
a very useful reference for this project).

