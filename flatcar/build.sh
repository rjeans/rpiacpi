#!/bin/bash
set -euo pipefail

PATCH_DIR="patches"
SUBMODULE_DIR="scripts"
REPO_URL="https://github.com/flatcar/scripts.git"
BRANCH="flatcar-4284"

# Ensure required directories exist
if [ ! -d "$PATCH_DIR" ]; then
  echo "ERROR: Patch directory '$PATCH_DIR' not found."
  exit 1
fi

# Clone or update the repository
if [ ! -d "$SUBMODULE_DIR" ]; then
  echo "==> Cloning repository: $REPO_URL"
  git clone --branch "$BRANCH" "$REPO_URL" "$SUBMODULE_DIR"
else
  echo "==> Updating repository in $SUBMODULE_DIR"
  cd "$SUBMODULE_DIR"
  git fetch origin
  git reset --hard "origin/$BRANCH"
  cd ..
fi

cd "$SUBMODULE_DIR"
echo "==> Entering submodule directory: $(pwd)"
echo "==> Checking and applying patches from ../$PATCH_DIR"
echo

PATCHES_APPLIED=0

for patch in ../"$PATCH_DIR"/*.patch; do
  patchname=$(basename "$patch")
  printf ">> Processing: %-45s ... " "$patchname"

  if git apply --reverse --check "$patch" > /dev/null 2>&1; then
    echo "SKIPPED (already applied)"
    continue
  elif git apply --check "$patch" > /dev/null 2>&1; then
    if git apply --index "$patch" > /dev/null 2>&1; then
      echo "APPLIED"
      PATCHES_APPLIED=$((PATCHES_APPLIED + 1))
    else
      echo "FAILED during application"
      exit 1
    fi
  else
    echo "FAILED to apply (not applicable or conflict)"
    exit 1
  fi
done

echo
echo "==> Patch application complete."

# Copy the patch file to the files directory
FILES_DIR="sdk_container/src/third_party/coreos-overlay/sys-kernel/coreos-sources/files"
SOURCE_PATCH="../../driver/patches/0001-Raspberry-Pi-PoE-ACPI-Drivers.patch"

if [ ! -d "$FILES_DIR" ]; then
  echo "==> Creating files directory: $FILES_DIR"
  mkdir -p "$FILES_DIR"
fi

echo "==> Copying patch file to files directory"
if cp "$SOURCE_PATCH" "$FILES_DIR/"; then
  echo "==> File copied successfully."
else
  echo "ERROR: Failed to copy patch file to $FILES_DIR"
  exit 1
fi


echo "==> Running SDK container and executing commands..."
./run_sdk_container -a arm64 <<EOF 2>&1 | tee build.log
echo "Starting build_packages..."
./trunk/src/scripts/build_packages --board=arm64-usr

echo "Packages built successfully, now building image..."
./trunk/src/scripts/build_image --board=arm64-usr --replace

echo "Build complete."
EOF
