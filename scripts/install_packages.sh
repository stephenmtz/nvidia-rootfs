#!/bin/bash

set -euo pipefail

ROOTFS="${1:-/workspace/rootfs}"
PACKAGES_FILE="${2:-/workspace/config/built_config.yaml"

if [ ! -d "$ROOTFS" ]; then
  echo "Error: rootfs directory not found: $ROOTFS"
  exit 1
fi

if [ ! -f "$PACKAGES_FILE" ]; then
  echo "Error: packages file not found: $PACKAGES_FILE"
  exit 1
fi

PACKAGES=$(grep -v '^\s*#' "$PACKAGES_FILE" \
  | grep -v '^\s*$' \
  | tr '\n' ' ')

if [ -z "$PACKAGES" ]; then
  echo "Error: no packages found in $PACKAGES_FILE"
  exit 1
fi

PACKAGES=$(yq eval '.packages | join(" ")' "$CONFIG_FILE")

echo "Installing packages: $PACKAGES"

chroot "$ROOTFS" /bin/bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y $PACKAGES
  apt-get clean
  rm -rf /var/lib/apt/lists/*
"

echo "All packages installed successfully"
