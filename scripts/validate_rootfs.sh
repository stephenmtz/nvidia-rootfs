#!/bin/bash

set -euo pipefail

ROOTFS="${1:-/workspace/rootfs}"
PACKAGES_FILE="${2:-/workspace/src/config/built_package.yaml}"

PASS=0
FAIL=0

check_pass() { echo "   $1"; PASS=$((PASS + 1)); }
check_fail() { echo "   FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "Checking rootfs structure"

if [ -d "$ROOTFS" ] && [ "$(ls -A $ROOTFS)" ]; then
  check_pass "rootfs directory exists and is not empty"
else
  check_fail "rootfs directory missing or empty"
fi

echo "Checking rootfs size"

SIZE=$(du -sb "$ROOTFS" | cut -f1)
SIZE_MB=$(echo "scale=1; $SIZE/1048576" | bc)

if [ "$SIZE" -gt 200000000 ]; then
  check_pass "rootfs size OK (${SIZE_MB} MB)"
else
  check_fail "rootfs too small (${SIZE_MB} MB) — expected > 200MB"
fi

echo "Checking critical system files"

for path in \
  "lib/systemd/systemd" \
  "etc/passwd" \
  "etc/fstab" \
  "bin/bash"; do
  if [ -e "$ROOTFS/$path" ]; then
    check_pass "$path present"
  else
    check_fail "$path missing"
  fi
done

if [ ! -f "$ROOTFS/usr/bin/qemu-aarch64-static" ]; then
  check_pass "qemu-aarch64-static correctly removed"
else
  check_fail "qemu-aarch64-static still present — remove before shipping"
fi

echo "Checking installed packages"

PACKAGES=$(grep -v '^\s*#' "$PACKAGES_FILE" | grep -v '^\s*$')

for pkg in $PACKAGES; do
  if chroot "$ROOTFS" dpkg -s "$pkg" > /dev/null 2>&1; then
    check_pass "$pkg installed"
  else
    check_fail "$pkg NOT installed"
  fi
done

echo "Verifying package integrity"

PACKAGES=$(grep '  - ' "$PACKAGES_FILE" | sed 's/  - //')

for pkg in $PACKAGES; do
  if chroot "$ROOTFS" dpkg -s "$pkg" | grep -q "Status: install ok installed"; then
    check_pass "$pkg is correctly installed in rootfs"
  else
    check_fail "$pkg is missing or failed to install"
  fi
done

echo "Checking Network Configuration"

if chroot "$ROOTFS" netplan generate > /dev/null 2>&1; then
  check_pass "Netplan configuration syntax is valid"
else
  check_fail "Netplan configuration is invalid"
fi

echo ""
echo "==============================="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "==============================="

if [ "$FAIL" -gt 0 ]; then
  echo "Validation FAILED — aborting build"
  exit 1
fi

echo "Validation PASSED — rootfs is ready"
exit 0
