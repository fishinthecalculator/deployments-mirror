#!/usr/bin/env sh

set -ex

here="$(dirname "$0")"
guix_root="$here/efraim-root"
rm -rfv "$guix_root"

guix_git ()  {
  cd "${HOME}/code/guix"
  guix shell --pure -D guix -- make -j6
  guix shell --pure -D guix -- ./pre-inst-env guix "$@"
}


dev="/dev/nvme0n1"
part="${dev}p1"


# Thanks to https://superuser.com/a/984637
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk "${dev}"
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF
sudo mkfs.ext4 -F $part
guix shell e2fsprogs -- sudo tune2fs -L Guix_image "${part}"

#old_uuid="$(guix shell util-linux -- blkid -s UUID -o value "$part")"
#guix shell btrfs-progs -- sudo btrfs-convert -L "$part"
#guix shell btrfs-progs -- sudo btrfs check --readonly "$part"
#guix shell btrfs-progs -- sudo btrfs filesystem label "$part" Guix_image
#guix shell btrfs-progs -- sudo btrfstune -U "$old_uuid" "$part"

tmp_config="/tmp/config.scm"

head -n -1 "${here}/system/config.scm" > "$tmp_config"
echo 'tarapia-one-partition-system' >> "$tmp_config"

sudo mount $part /mnt
sudo -E guix system init "$tmp_config" /mnt
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
sudo umount /mnt
rm -rfv "$tmp_config"
