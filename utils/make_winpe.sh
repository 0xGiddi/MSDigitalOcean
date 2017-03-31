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

# Get the case sensaive system32 path  (It's diffren between WinPE WIM files)
sys32="$(dirname $(wimlib-imagex dir "$dstDir"/boot.wim  |  grep -Poie "^/windows/system32/cmd.exe$"))"

# Find the arch and windows version for injecting drivers
winVersion="$(wimlib-imagex info "$dstDir"/boot.wim | grep ".Version" | awk 'NR%2{printf "%s.",$3;next;}{print $3}')"
winArch="$(wimlib-imagex info "$dstDir"/boot.wim | grep "Architecture" | awk '{print $2}')"

# Create a wim update File
echo "Command file is: $cmdFile"
cat > "$cmdFile" <<EOF
rename /setup.exe /setup.exe.org
rename /sources/setup.exe /sources/setup.exe.org
add $orgDir/winpe_utils/drivers/$winVersion/$winArch/ /drivers/
add $orgDir/winpe_utils/winpeshl.ini $sys32/winpeshl.ini
add $orgDir/winpe_utils/loadDrivers.cmd $sys32/loadDrivers.cmd
add $orgDir/winpe_utils/script.vbs $sys32/autoinstaller.vbs
EOF

# update the wim, but make sure that internal script files are all DOS formatted
unix2dos "$orgDir"/winpe_utils/loadDrivers.cmd
unix2dos "$orgDir"/winpe_utils/winpeshl.ini
wimlib-imagex update "$dstDir"/boot.wim --rebuild < "$cmdFile"

cp "$dstDir"/boot.wim "$orgDir"/../server/stage1/boot/boot.wim


