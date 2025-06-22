# rpiacpi

**EDK2 UEFI firmware customization for Raspberry Pi with ACPI support and PoE HAT fan integration**

This repository builds a custom UEFI firmware image for the Raspberry Pi 4, using the EDK2 UEFI firmware framework. It adds ACPI support for the Raspberry Pi PoE HAT fan via a DXE driver and a generated SSDT (Secondary System Description Table).

This is useful when running ACPI-capable OSes like Flatcar Linux on the Pi, allowing the fan to appear as a standard ACPI thermal zone and be managed automatically by the OS.

---

## Features

- Builds UEFI firmware for Raspberry Pi 4 using EDK2 and Docker.
- Adds support for the PoE HAT fan via ACPI SSDT and DXE driver.
- Custom ACPI table (`PoeFanSsdt`) generated via Python and included in firmware.
- Tested with Flatcar Linux on Raspberry Pi using UEFI boot.

---

## Repository Structure

```
rpiacpi/
├── build.sh                     # Entry-point build script using Docker
├── Dockerfile                  # Defines EDK2 build environment
├── edk2-rpiacpi/               # EDK2 source tree + custom platform/driver
│   ├── Platforms/QEMUACPI/
│   │   ├── ArmVirtPoeQemu.dsc  # EDK2 platform config with custom drivers
│   │   └── ArmVirtPoeQemu.fdf  # Flash layout embedding SSDT
│   └── Drivers/PoeFanDxe/
│       ├── PoeFanDxe.c         # DXE driver to expose fan control
│       ├── PoeFanDxe.inf       # EDK2 driver description
│       ├── PoeFanSsdt.asl      # Base ACPI source (ASL)
│       ├── PoeFanSsdt.c        # C array for embedding AML in firmware
│       ├── PoeFanSsdt.aml      # Compiled ACPI AML table
│       └── generate_ssdt.py    # Generates AML and C headers from ASL
```

---

## Requirements

- Docker
- `git` (with submodule support)

---

## Quick Start

### 1. Clone and Initialize

```bash
git clone https://github.com/rjeans/rpiacpi.git --recurse-submodules
cd rpiacpi
```

### 2. Build the Docker Image

```bash
docker build -t edk2-builder .
```

### 3. Build the Firmware

Run the provided script:

```bash
./build.sh
```

This:
- Compiles the custom DXE driver (`PoeFanDxe`)
- Generates the ACPI table (`PoeFanSsdt.aml`) and embeds it into the firmware
- Produces the final UEFI image:  
  `Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd`

### 4. Test or Deploy

You can:
- Flash this firmware to a Raspberry Pi’s UEFI boot medium
- Use it with QEMU (`-bios QEMU_EFI.fd`) for aarch64 testing

The PoE fan ACPI device will appear to the OS as a thermal-controlled fan device.

---

## Manual Build

For debugging or manual steps:

```bash
docker run -it --rm -v $PWD:/workspace edk2-builder bash
```

From inside the container, you can build the firmware manually with `build -a AARCH64 -p Platforms/QEMUACPI/ArmVirtPoeQemu.dsc`.

---

## Notes

- The ACPI table is embedded using a `.fdf` flash descriptor (`ArmVirtPoeQemu.fdf`).
- ACPI table generation uses Python (`generate_ssdt.py`) to convert ASL to AML and C.
- The PoE fan driver currently assumes standard GPIO-based fan control supported on Pi HATs.

---

## License

This project includes code from the EDK2 project (BSD License). All original code in this repo is provided under the MIT License unless otherwise noted.

---

## Author

[@rjeans](https://github.com/rjeans)
