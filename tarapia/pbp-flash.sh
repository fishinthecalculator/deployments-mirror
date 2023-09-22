#!/usr/bin/env sh
set -eu

default_dev="/dev/nvme0n1"

if [ "$#" -eq 0 ]; then
  echo "You must pass an IMAGE!" >&2
  echo "Usage $(basename "$0") IMAGE [DEVICE]" >&2
  echo "DEVICE defaults to ${default_dev}." >&2
  exit 1
elif [ "$#" -eq 1 ]; then
  dev="$default_dev"
elif [ "$#" -ge 2 ]; then
  dev="$2"
fi

image="$1"


sudo dd "if=${image}" "of=${dev}" bs=4M status=progress oflag=sync
sync
