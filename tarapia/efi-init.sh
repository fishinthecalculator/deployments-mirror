#!/usr/bin/env sh

set -eu

[ "$#" -ne 1 ] && echo "Usage: $(basename "$0") OPERATING-SYSTEM-NAME" >&2 && exit 1


set -x

here="$(dirname "$0")"
system_name="$1"
guix_root="${here}/${system_name}-root"
rm -rfv "$guix_root"

dev="/dev/nvme0n1"
esp_part="${dev}p1"
root_part="${dev}p2"

cat << EOF | "${here}/auto-fdisk" "${dev}"
    g # clear the in memory partition table
    n # new partition
      # default, partition number 1
      # default - start at beginning of disk
83967 # 83967, i.e. 42MB for ESP
    x # enable expert mode
    A # make a partition bootable
    r # exit Expert mode
    n # new partition
      # default, partition number 2
      # default - start at 83968
      # default, extend partition to end of disk
    p # print the in-memory partition table
    v # verify the in-memory partition table
    w # write the partition table
    q # and we're done
EOF


# ESP
sudo mkfs.vfat -F 32 $esp_part
guix shell dosfstools -- sudo fatlabel "${esp_part}" GNU-ESP

# Root
sudo mkfs.ext4 -F $root_part
guix shell e2fsprogs -- sudo tune2fs -L guix-root "${root_part}"

"${here}/config_trick" "$system_name" "${here}/system/config.scm"

sudo mount $root_part /mnt
sudo mkdir -p /mnt/boot
sudo mount $esp_part /mnt/boot

sudo -E guix time-machine -C "${here}/channels.scm" -- system init /tmp/config.scm /mnt

sudo umount /mnt/boot/efi
sudo rm -rfv /mnt/boot
sudo umount /mnt
rm -rfv "/tmp/config.scm"

guix shell e2fsck-static -- sudo -E e2fsck "$root_part"
