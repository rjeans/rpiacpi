#!/bin/bash
set -euo pipefail

# Settings
LINUX_REPO="https://github.com/torvalds/linux.git"
LINUX_BRANCH="v6.6"  # or use coreos-specific tag if known
WORKDIR="build/linux"
PATCHES_DIR="patches"
SRC_DIR="src"
PATCH_NAME="0001-Raspberry-Pi-PoE-ACPI-Drivers.patch"

# Cleanup old working tree
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# Clone Linux source
echo "Cloning Linux $LINUX_BRANCH..."
git clone --depth=1 --branch "$LINUX_BRANCH" "$LINUX_REPO" "$WORKDIR"

cd "$WORKDIR"

# Create a new branch for patching
git checkout -b rpi-poe-acpi

# Add your custom driver
mkdir -p drivers/acpi/rpi
cp -v ../../"$SRC_DIR"/*.c drivers/acpi/rpi/
cp -v ../../"$SRC_DIR"/*.h drivers/acpi/rpi/

# Update drivers/acpi/Makefile
echo -e "\nobj-y += rpi/" >> drivers/acpi/Makefile

# Update drivers/acpi/Kconfig
cat << 'EOF' >> drivers/acpi/Kconfig

menu "Raspberry Pi ACPI support"

config RPI_ACPI_THERMAL
    tristate "Raspberry Pi ACPI thermal zone driver"
    depends on ACPI
    default n

config RPI_MAILBOX
    tristate "Raspberry Pi ACPI mailbox"
    depends on ACPI
    default n

config RPI_PWM_POE
    tristate "Raspberry Pi PoE PWM (via mailbox)"
    depends on RPI_MAILBOX
    default n

config RPI_PWM_FAN
    tristate "Raspberry Pi PWM fan"
    depends on ACPI && PWM
    default n

endmenu
EOF

# Add rpi/Kconfig and link it if needed (optional: modular per-file config)

# Stage changes and generate patch
git add drivers/acpi/rpi drivers/acpi/Makefile drivers/acpi/Kconfig
git commit -m "Raspberry Pi PoE ACPI Drivers"

# Ensure patch output directory
mkdir -p ../"$PATCHES_DIR"

# Create the patch
git format-patch -1 HEAD --output=../"$PATCHES_DIR"/"$PATCH_NAME"

echo "Patch created: $PATCHES_DIR/$PATCH_NAME"

