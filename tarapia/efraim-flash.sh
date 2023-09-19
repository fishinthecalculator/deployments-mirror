set -ex

guix-git ()  {
  cd $HOME/code/guix
  guix shell --pure -D guix -- make -j6
  guix shell --pure -D guix -- ./pre-inst-env guix "$@"
}

guix_commit="0dc83ce53b8bad8473c80689ba212d9f9bb712b3"
here="$(dirname "$0")"
guix_root="$here/efraim-root"
rm -rfv "$guix_root"
dev="/dev/nvme0n1"
part="${dev}p2"
image="$(guix system image -r "$guix_root"  --image-type=efi-raw "$here/system/config.scm" "$@")"


sudo dd "if=${image}" "of=${dev}" bs=4M status=progress oflag=sync
sync
sudo cfdisk "$dev"
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
#old_uuid="$(guix shell util-linux -- blkid -s UUID -o value "$part")"
#guix shell btrfs-progs -- sudo btrfs-convert -L "$part"
#guix shell btrfs-progs -- sudo btrfs check --readonly "$part"
#guix shell btrfs-progs -- sudo btrfs filesystem label "$part" Guix_image
#guix shell btrfs-progs -- sudo btrfstune -U "$old_uuid" "$part"
