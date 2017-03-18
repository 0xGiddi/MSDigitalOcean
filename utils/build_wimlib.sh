#!/bin/bash

# build_wimlib.sh
# Build wimlib tools in order to manipulate the WinPE wim file

tmpDir="$(mktemp -d)"
orgDir=$(pwd)


sudo apt-get install -y libxml2 gettext libfuse-dev libattr1-dev git build-essential libssl-dev p7zip-full fuseiso ipmitool libbz2-dev ntfs-3g-dev

git clone git://wimlib.net/wimlib "$tmpDir"
cd "$tmpDir"
./bootstrap
./configure --prefix=/usr
make -j$(nproc)
sudo make install

# Rebuild shared lib cache
sudo ldconfig
#ldconfig -p | grep libwim 

