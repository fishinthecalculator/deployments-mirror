set -ex

dev="/dev/nvme0n1"
part="${dev}p1"
image="$(guix system image -e '(@ (gnu system images pinebook-pro) pinebook-pro-barebones-raw-image)' --system=aarch64-linux)"

sudo dd "if=${image}" "of=${dev}" bs=4M status=progress oflag=sync
sync
sudo reboot
sudo cfdisk "$dev"
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
