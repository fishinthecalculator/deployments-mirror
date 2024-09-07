#!/usr/bin/env sh

set -eu

[ "$#" -ne 1 ] && echo "Usage: $(basename "$0") OPERATING-SYSTEM-NAME" >&2 && exit 1


set -x

here="$(dirname "$0")"
system_name="$1"
guix_root="${here}/${system_name}-root"
rm -rfv "$guix_root"

dev="/dev/nvme0n1"
part="${dev}p1"

cat << EOF | "${here}/auto-fdisk" "${dev}"
  g # clear the in memory partition table
  n # new partition
    # default, partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  x # enable expert mode
  A # make a partition bootable
  p # print the in-memory partition table
  v # verify the in-memory partition table
  r # exit Expert mode
  w # write the partition table
  q # and we're done
EOF
sudo mkfs.ext4 -F $part
guix shell e2fsprogs -- sudo tune2fs -L guix-root "${part}"

#old_uuid="$(guix shell util-linux -- blkid -s UUID -o value "$part")"
#guix shell btrfs-progs -- sudo btrfs-convert -L "$part"
#guix shell btrfs-progs -- sudo btrfs check --readonly "$part"
#guix shell btrfs-progs -- sudo btrfs filesystem label "$part" guix-root
#guix shell btrfs-progs -- sudo btrfstune -U "$old_uuid" "$part"

"${here}/config_trick" "$system_name" "${here}/system/config.scm"

sudo mount $part /mnt
sudo -E guix time-machine -C "${here}/channels.scm" -- system init /tmp/config.scm /mnt
sudo umount /mnt
rm -rfv "/tmp/config.scm"

guix shell e2fsck-static -- sudo -E e2fsck "$part"
