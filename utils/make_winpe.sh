#!/bin/bash

# make_wim
# Build the wimboot module for stage0

if [ -f $1 ]; then
   echo "Using $1 for WInPE image"
else
   echo "File $1 does not exist. Please use a valid ISO."
   exit
fi

tmpDir="$(mktemp -d)"
dstDir="$(mktemp -d)"
cmdFile="$(mktemp)"
orgDir=$(pwd)

# Export the wim image
sudo mount $1 $tmpDir
wimlib-imagex export "$tmpDir"/sources/boot.wim 2 --boot "$dstDir"/boot.wim 

# Find the arch and windows version for injecting drivers
winVersion="$(wimlib-imagex info "$dstDir"/boot.wim | grep ".Version" | awk 'NR%2{printf "%s.",$3;next;}{print $3}')"
winArch="$(wimlib-imagex info "$dstDir"/boot.wim | grep "Architecture" | awk '{print $2}')"

# Create a wim update File
echo "Command file is: $cmdFile"
cat > "$cmdFile" <<EOF
rename /setup.exe /setup.exe.org
rename /sources/setup.exe /sources/setup.exe.org
add $orgDir/winpe_utils/wget.exe /windows/system32/wget.exe
add $orgDir/winpe_utils/imagex.exe /windows/system32/imagex.exe
add $orgDir/winpe_utils/drivers/$winVersion/$winArch/ /drivers/
add $orgDir/winpe_utils/winpehl.ini /windows/system32/winpehl.ini
add $orgDir/winpe_utils/loader.cmd /windows/system32/loader.cmd
EOF

# update the wim, but make sure that internal script files are all DOS formatted
unix2dos "$orgDir"/winpe_utils/startnet.cmd
unix2dos "$orgDir"/winpe_utils/winpehl.ini
wimlib-imagex update "$dstDir"/boot.wim --check < "$cmdFile"

cp "$dstDir"/boot.wim "$orgDir"/../server/stage1/boot/boot.wim


