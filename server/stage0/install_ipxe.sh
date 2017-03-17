#!/usr/bin/env bash

# ipxe_install.sh
# Download the IPXE kernel and ad a IPXE initrd script

IMAGE_SERVER_ADDR=""
IPXE_KEREL_LOC="/boot/ipxe.lkrn"
IPXE_INITRD_LOC="/boot/ipxe-initrd"


mdPublicAddr="$(curl http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)"
mdPublicMask="$(curl http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/netmask)"
mdPublicGW="$(curl http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/gateway)"

echo "Setting IPXE kernel"
wget "http://$IMAGE_SERVER_ADDR/stage0/ipxe.lkrn" -O $IPXE_KEREL_LOC

echo "Generating IPXE initrd file"
cat > /boot/ipxe-initrd <<EOF
#!ipxe
imgfree
set net0/ip $mdPublicAddr
set net0/netmask $mdPublicMask
set net0/gateway $mdPublicGW
set dns 8.8.8.8
ifopen net0
chain --autofree http://$IMAGE_SERVER_ADDR/stage1/loader.ipxe || shell 
EOF

echo "Creating custom GRUB configuration"
cat >>  /etc/grub.d/40_custom <<EOF
menuentry 'chainload' {
    set root='hd0,gpt1'
    linux16 /boot/ipxe.lkrn
    initrd16 /boot/ipxe-initrd
}
EOF

echo "Updating default grub option"
sed -i 's/^\(GRUB_DEFAULT\s*=\s*\).*$/\1chainload/' /etc/default/grub

echo "Generating new GRUB config"
grub-mkconfig -o /boot/grub/grub.cfg

echo "Rebooting"
# reboot now

