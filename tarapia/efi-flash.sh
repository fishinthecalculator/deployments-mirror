#!/usr/bin/env sh

set -eu

[ "$#" -ne 1 ] && echo "Usage: $(basename "$0") OPERATING-SYSTEM-NAME" >&2 && exit 1


set -x

here="$(dirname "$0")"
system_name="$1"
guix_root="${here}/${system_name}-root"
rm -rfv "$guix_root"

guix_git ()  {
  cd "${HOME}/code/guix"
  guix shell --pure -D guix -- make -j6
  guix shell --pure -D guix -- ./pre-inst-env guix "$@"
}

image () {
    "${here}/config_trick" "$system_name" "${here}/system/config.scm"
    guix time-machine -C "${here}/channels.scm" -- system image -r "$guix_root"  --image-type=efi-raw "/tmp/config.scm"
}


dev="/dev/nvme0n1"
part="${dev}p2"

"${here}/pbp-flash.sh" "$(image)" "${dev}"

sudo cfdisk "$dev"
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
#old_uuid="$(guix shell util-linux -- blkid -s UUID -o value "$part")"
#guix shell btrfs-progs -- sudo btrfs-convert -L "$part"
#guix shell btrfs-progs -- sudo btrfs check --readonly "$part"
#guix shell btrfs-progs -- sudo btrfs filesystem label "$part" guix-root
#guix shell btrfs-progs -- sudo btrfstune -U "$old_uuid" "$part"

rm -rfv "/tmp/config.scm"
