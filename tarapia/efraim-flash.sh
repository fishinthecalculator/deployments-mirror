set -ex

here="$(dirname "$0")"
guix_root="$here/efraim-root"
rm -rfv "$guix_root"

guix_git ()  {
  cd "${HOME}/code/guix"
  guix shell --pure -D guix -- make -j6
  guix shell --pure -D guix -- ./pre-inst-env guix "$@"
}

image () {
    guix time-machine -C "${here}/channels.scm" -- system image -r "$guix_root"  --image-type=efi-raw "$here/system/config.scm"
}


dev="/dev/nvme0n1"
part="${dev}p2"


sudo dd "if=$(image)" "of=${dev}" bs=4M status=progress oflag=sync
sync
sudo cfdisk "$dev"
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
#old_uuid="$(guix shell util-linux -- blkid -s UUID -o value "$part")"
#guix shell btrfs-progs -- sudo btrfs-convert -L "$part"
#guix shell btrfs-progs -- sudo btrfs check --readonly "$part"
#guix shell btrfs-progs -- sudo btrfs filesystem label "$part" Guix_image
#guix shell btrfs-progs -- sudo btrfstune -U "$old_uuid" "$part"
