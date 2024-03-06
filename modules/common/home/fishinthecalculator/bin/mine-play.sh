#!/usr/bin/env sh

set -eu

sudo herd stop wireguard-wg0
guix shell zerotier -- sudo zerotier-one -d
guix shell zerotier -- sudo zerotier-cli join 60ee7c034a9cce0e

export DRI_PRIME=1
prismlauncher

guix shell zerotier -- sudo zerotier-cli leave 60ee7c034a9cce0e
sudo herd start wireguard-wg0
