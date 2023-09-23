set -ex

here="$(dirname "$0")"
dev="/dev/nvme0n1"
part="${dev}p1"
image="$(guix time-machine -C "${here}/channels.scm" -- system image --image-type=pinebook-pro-raw -e '(@ (gnu system images pinebook-pro) pinebook-pro-barebones-os)' --system=aarch64-linux)"


"${here}/pbp-flash.sh" "${image}" "${dev}"

sudo cfdisk "$dev"
guix shell e2fsprogs -- sudo resize2fs "$part"
guix shell e2fsck-static -- sudo -E e2fsck "$part"
