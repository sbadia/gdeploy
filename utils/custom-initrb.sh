#!/bin/sh
echo "Aide à la création d'initrd perso"
cd /root
mkdir initrd
cd initrd
echo "--> utilisation de l'initrd $(uname -r)"
gzip -dc /boot/initrd-$(uname -r).img | cpio -id --no-absolute-filenames
ls
vim init
echo "--> création"
find . | cpio --dereference -H newc -o | gzip -9 > /boot/initrd-$(uname -r).img
