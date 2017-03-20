#!/bin/bash

# build_wimboot.sh
# Build the wimboot module for stage0

tmpDir="$(mktemp -d)"
orgDir=$(pwd)

sudo apt-get update
sudo apt-get install -y pesign libiberty-dev binutils-dev
git clone https://git.ipxe.org/wimboot.git "$tmpDir"


cd "$tmpDir"/src
make clean
make wimboot
cd "$orgDir" 
cp "$tmpDir"/wimboot ../server/stage1/wimboot