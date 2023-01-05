#!/usr/bin/env sh
set -ueo pipefail

BOOT_PART="/dev/sda1"
SYS_PART="/dev/sda2"

sudo cryptsetup open $SYS_PART luks

sudo mount -o subvol=root,compress=zstd,noatime /dev/mapper/luks /mnt/
sudo mount $BOOT_PART /mnt/boot/
sudo mount -o subvol=home,compress=zstd,noatime /dev/mapper/luks /mnt/home/
sudo mount -o subvol=nix,compress=zstd,noatime /dev/mapper/luks /mnt/nix/
sudo mount -o subvol=log,compress=zstd,noatime /dev/mapper/luks /mnt/var/log/

sudo nixos-enter
NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot

