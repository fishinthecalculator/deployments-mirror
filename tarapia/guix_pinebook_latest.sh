set -ex

guix_commit="17d9a91e6b8bdd7709b536d34a1f2ef3fcff3b9d"
dev="/dev/nvme0n1"
part="${dev}p1"
image="$(guix time-machine --commit=$guix_commit -- system image --image-type=pinebook-pro-raw -e '(@ (gnu system images pinebook-pro) pinebook-pro-barebones-os)' --system=aarch64-linux)"

sudo dd "if=${image}" "of=${dev}" bs=4M status=progress oflag=sync
sync
sudo cfdisk "$dev"
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
