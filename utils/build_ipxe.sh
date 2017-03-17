#!/bin/bash

# build_ipxe.sh
# Build he IPXE kernel for stage0

tmpDir="$(mktemp -d)"
orgDir=$(pwd)

sudo apt-get install -y build-essential liblzma-dev git
git clone git://git.ipxe.org/ipxe.git "$tmpDir"


cd "$tmpDir"/src
# At some point enable HTTPS support and add cerificates
make bin/ipxe.lkrn
cd "$orgDir" 
cp "$tmpDir"/src/bin/ipxe.lkrn ../server/stage0/ipxe.lkrn