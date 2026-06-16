# nvidia-rootfs

Automated pipeline that customizes the official NVIDIA Jetson Linux sample root filesystem for the AGX Orin and uploads it to Google Cloud Storage.

## What it does

1. Pulls the NVIDIA base rootfs from GCS
2. Installs packages defined in `config/packages.txt`
3. Validates the rootfs
4. Repacks it as a tarball with a commit SHA in the filename
5. Uploads it to GCS with a SHA256 checksum and manifest

## Usage

Add or remove packages by editing `config/packages.txt` and pushing to main. The pipeline triggers automatically.

## Stack

- GitHub Actions
- Google Cloud Build
- Google Cloud Storage
- Google Secret Manager
- QEMU (ARM64 emulation)