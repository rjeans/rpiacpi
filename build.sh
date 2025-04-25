#!/bin/bash

set -e

# Define constants
FLASH_SIZE_MB=64
TOOLCHAIN=GCC5
ARCH=AARCH64
FIRMWARE_NAME=RPI_EFI
OUTPUT_DIR=firmware


# Define file paths
DSC="edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Set environment variables for the build
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export PACKAGES_PATH="$PWD/edk2:$PWD/edk2-platforms:$PWD/edk2-non-osi"
export WORKSPACE=$PWD

# Source the EDK2 build environment
if ! source "edk2/edksetup.sh"; then
    echo "Failed to source edksetup.sh. Ensure the file exists and is accessible."
    exit 1
fi

# Build BaseTools
if ! make -C "edk2/BaseTools"; then
    echo "Failed to build BaseTools. Check the output for errors."
    exit 1
fi

# Build the firmware
if ! build -a "$ARCH" -t "$TOOLCHAIN" -p "$DSC" -b RELEASE ; then
    echo "Firmware build failed. Check the output for errors."
    exit 1
fi

# Verify the firmware file exists
if [ ! -f  Build/RPi4Poe/RELEASE_GCC5/FV/RPI_EFI.fd ]; then
    echo "Build failed. Firmware file not found."
    exit 1
fi

cp Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/QEMU_EFI.fd $OUTPUT_DIR

