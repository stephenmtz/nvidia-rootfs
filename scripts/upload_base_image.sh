#!/bin/bash

set -euo pipefail

ROOTFS_FILE="${1:-}"
GCS_BUCKET="${2:-}"

if [ -z "$ROOTFS_FILE" ] || [ -z "$GCS_BUCKET" ]; then
  echo "Usage: $0 <path-to-tbz2> <gcs-bucket>"
  echo "Example: $0 ~/Downloads/nvidia-rootfs-r36.3.0.tbz2 your-org-agx-rootfs"
  exit 1
fi

if [ ! -f "$ROOTFS_FILE" ]; then
  echo "Error: file not found: $ROOTFS_FILE"
  exit 1
fi

FILENAME=$(basename "$ROOTFS_FILE")

echo "Uploading $FILENAME to gs://$GCS_BUCKET/base-images/..."
gsutil cp "$ROOTFS_FILE" "gs://$GCS_BUCKET/base-images/$FILENAME"

echo ""
echo "Done. Base image available at:"
echo "gs://$GCS_BUCKET/base-images/$FILENAME"
echo ""
echo "Update gcp_build.yaml substitution:"
echo "_BASE_IMAGE: '$FILENAME'"
