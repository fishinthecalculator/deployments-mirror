set -ex

dev="/dev/nvme0n1"
part="${dev}p1"

sudo parted -- $dev mkpart p 0% -1
sudo parted -- $dev set 1 boot on
sudo mkfs.ext4 -F $part
guix shell btrfs-progs -- sudo btrfs-convert -L $part
sudo mount $part /mnt
sudo -E guix system init /home/paul/Scaricati/arm-baar.scm /mnt
sudo umount /mnt
