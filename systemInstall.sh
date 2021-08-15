#!/bin/sh

# Taken from: https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html

# Create boot partition /dev/sdaZ
BOOT_PART="/dev/sda1"
# Create swap partition /dev/sdaY
SWAP_PART="/dev/sda3"
# Create empty system partition /dev/sdaX
SYS_PART="/dev/sda2"
# Then:

nix-env -iA nixos.htop
nix-env -iA nixos.git-crypt

sudo swapon $SWAP_PART

sudo cryptsetup luksFormat $SYS_PART
sudo cryptsetup open $SYS_PART luks

sudo mkfs.btrfs /dev/mapper/luks

sudo mount -t btrfs /dev/mapper/luks /mnt
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/log

sudo umount /mnt

sudo mount -o subvol=root,compress=zstd,noatime /dev/mapper/luks /mnt/

sudo mkdir /mnt/home
sudo mkdir /mnt/nix
sudo mkdir -p /mnt/var/log
sudo mkdir /mnt/boot

sudo mount $BOOT_PART /mnt/boot/
sudo mount -o subvol=home,compress=zstd,noatime /dev/mapper/luks /mnt/home/
sudo mount -o subvol=nix,compress=zstd,noatime /dev/mapper/luks /mnt/nix/
sudo mount -o subvol=log,compress=zstd,noatime /dev/mapper/luks /mnt/var/log/


# Finally
sudo nixos-generate-config --root /mnt

sudo nano /mnt/etc/nixos/*.nix

# When done modifying:
# sudo nixos-install --root /mnt
# sudo reboot

