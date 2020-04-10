#!/bin/bash

# When you change this file, you must take manual action. Read this doc:
# - https://docs.sandstorm.io/en/latest/vagrant-spk/customizing/#setupsh

set -euo pipefail

export HUGO_VERSION=0.68.3
export NODE_VERSION=10

apt-get update
apt-get install -y git strace

# First, get capnproto from master and install it to
# /usr/local/bin. This requires a C++ compiler. We opt for gcc-6
# because that's what capnproto now requires.
if [ ! -e /usr/local/bin/capnp ] ; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q clang autoconf pkg-config libtool
    cd /tmp
    if [ ! -e capnproto ]; then git clone https://github.com/capnproto/capnproto; fi
    cd capnproto
    #git checkout master
    git checkout master
    cd c++
    make clean || true
    autoreconf -i
    ./configure
    make -j2
    sudo make install
fi

rm /opt/app/sandstorm-integration/getPublicId || true
rm -Rf /opt/app/sandstorm-integration/tmp || true

# Second, compile the small C++ program within
# /opt/app/sandstorm-integration.
if [ ! -e /opt/app/sandstorm-integration/getPublicId ] ; then
    pushd /opt/app/sandstorm-integration
    make clean || true
    make
fi

cp /opt/app/sandstorm-integration/bin/getPublicId /usr/local/bin

curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
apt-get install -y nodejs
npm install -g yarn

apt-get install -y python-pip asciidoctor
pip install pygments

cd /tmp
wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.deb -O hugo.deb
dpkg -i hugo.deb
rm hugo.deb
