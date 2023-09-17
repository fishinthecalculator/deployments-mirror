set -ex

guix_root="/home/paul/Scaricati/guix-pinebook-latest-root"
rm -rfv "$guix_root"

guix='cd /home/paul/Scaricati/guix; make -j6 && guix shell -D guix -- ./pre-inst-env guix'
dev="/dev/nvme0n1"
part="${dev}p1"
image="$(guix system image -r "$guix_root" -e '(@ (gnu system images pinebook-pro) pinebook-pro-barebones-raw-image)' --system=aarch64-linux)"

sudo dd "if=${image}" "of=${dev}" bs=4M status=progress oflag=sync
sync
sudo reboot
#sudo cfdisk "$dev"
#guix shell e2fsprogs -- sudo resize2fs "$part"
#guix shell e2fsck-static -- sudo -E e2fsck "$part"
#guix shell btrfs-progs -- sudo btrfs-convert -L "$part"
#guix shell btrfs-progs -- sudo btrfs filesystem label "$part" Guix_image
