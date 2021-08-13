#!/bin/sh

# Taken from: https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html

# Create boot partition /dev/sdaZ
# Create swap partition /dev/sdaY
# Create empty system partition /dev/sdaX
# Then:

nix-env -iA nixos.htop
nix-env -iA nixos.git-crypt

#sudo swapon /dev/sdaY

#sudo cryptsetup luksFormat /dev/sdaX
#sudo cryptsetup open /dev/sdaX luks

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

#sudo mount /dev/sdaZ /mnt/boot/
sudo mount -o subvol=home,compress=zstd,noatime /dev/mapper/luks /mnt/home/
sudo mount -o subvol=nix,compress=zstd,noatime /dev/mapper/luks /mnt/nix/
sudo mount -o subvol=log,compress=zstd,noatime /dev/mapper/luks /mnt/var/log/


# Finally
sudo nixos-generate-config --root /mnt

sudo nano /mnt/etc/nixos/*.nix

# When done modifying:
# sudo nixos-install --root /mnt
# sudo reboot

