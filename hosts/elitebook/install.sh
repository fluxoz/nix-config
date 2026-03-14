#!/usr/bin/env bash

export NIX_CONFIG='experimental-features = nix-command flakes'

nix run github:nix-community/disko/latest -- --mode destroy,format,mount "./hosts/$1/disks.nix" --yes-wipe-all-disks

mkdir -p /mnt/var/lib/jellyfin/conf
mkdir -p /mnt/var/lib/jellyfin/data

nixos-generate-config --root /mnt

nixos-install --flake .#nuc --impure
