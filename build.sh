#!/bin/bash

set -e

# Define constants
FLASH_SIZE_MB=64
TOOLCHAIN=GCC5
ARCH=AARCH64
FIRMWARE_NAME=QEMU_EFI_64M
OUTPUT_DIR=firmware


# Define file paths
POE_SSDT_ASL_FILE="edk2-rpiacpi/Drivers/PoeFanDxe/PoeFanSsdt.asl"
GENERATE_SCRIPT="edk2-rpiacpi/Drivers/PoeFanDxe/generate_ssdt.py"
DSC="edk2-rpiacpi/Platforms/QEMUACPI/ArmVirtPoeQemu.dsc"

# Define environment variables
PYTHON=${PYTHON:-python3}

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Set environment variables for the build
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export PACKAGES_PATH="$PWD/edk2:$PWD/edk2-rpiacpi"
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

# Generate SSDT
if ! "$PYTHON" "$GENERATE_SCRIPT" "$POE_SSDT_ASL_FILE"; then
    echo "Failed to run generate_ssdt.py. Check the output for errors."
    exit 1
fi

# Build the firmware
if ! build -a "$ARCH" -t "$TOOLCHAIN" -p "$DSC" -b RELEASE ; then
    echo "Firmware build failed. Check the output for errors."
    exit 1
fi

# Verify the firmware file exists
if [ ! -f Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/QEMU_EFI.fd ]; then
    echo "Build failed. Firmware file not found."
    exit 1
fi

# Copy and truncate the firmware file
FIRMWARE_RAW="$OUTPUT_DIR/${FIRMWARE_NAME}.fd"
cp Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/QEMU_EFI.fd "$FIRMWARE_RAW"
truncate -s "${FLASH_SIZE_MB}M" "$FIRMWARE_RAW"

# Convert the firmware to QCOW2 format
FIRMWARE_QCOW2="$OUTPUT_DIR/${FIRMWARE_NAME}.qcow2"
if ! qemu-img convert -f raw -O qcow2 "$FIRMWARE_RAW" "$FIRMWARE_QCOW2"; then
    echo "Failed to convert firmware to QCOW2 format."
    exit 1
fi

# Create and convert the NVRAM file
VARS_RAW="$OUTPUT_DIR/vars.fd"
VARS_QCOW2="$OUTPUT_DIR/vars.qcow2"
if ! dd if=/dev/zero of="$VARS_RAW" bs=1M count=$FLASH_SIZE_MB; then
    echo "Failed to create NVRAM raw file."
    exit 1
fi
if ! qemu-img convert -f raw -O qcow2 "$VARS_RAW" "$VARS_QCOW2"; then
    echo "Failed to convert NVRAM to QCOW2 format."
    exit 1
fi

# Output success messages
echo "Firmware QCOW2 created at: $FIRMWARE_QCOW2"
echo "NVRAM QCOW2 created at: $VARS_QCOW2"
