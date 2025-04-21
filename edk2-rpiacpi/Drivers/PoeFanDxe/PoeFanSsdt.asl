/*
 * SSDT for Raspberry Pi PoE HAT Fan Control
 * Provides GPIO-based fan control with a _DSM interface
 * to set and get fan speed levels dynamically.
 *
 * ACPI Table Signature: SSDT
 * OEM ID: "RPI"
 * OEM Table ID: "POEFAN"
 * Table Revision: 1
 */

DefinitionBlock ("PoeFanSsdt.aml", "SSDT", 2, "RPI", "POEFAN", 0x00000001)
{
    Scope (_SB)
    {
        Device (FAN0)
        {
            // Hardware ID - custom identifier for the fan device
            Name (_HID, "RPI0001")

            // Unique ID for distinguishing similar devices
            Name (_UID, 0x01)

            // Status - device is enabled and functioning
            Name (_STA, 0x0F)

            // Declare the GPIO resource used to control the fan (GPIO pin 13)
            Method (_CRS, 0, NotSerialized)
            {
                Return (ResourceTemplate ()
                {
                    GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                        "\\_SB.GPO0", 0, ResourceConsumer,,)
                    {
                        13
                    }
                })
            }

            // UUID to identify this custom _DSM interface
            Name (UUID, Buffer() {
                0xF2, 0xB4, 0xE1, 0xD3, 0xA8, 0xF0, 0x4D, 0x2A,
                0xB0, 0xE0, 0xD6, 0xA8, 0x8F, 0x90, 0xFB, 0xFD
            })

            // Current fan speed level (0 = off, 1 = on)
            Name (STLV, 0)

            /*
             * _DSM (Device Specific Method)
             * Provides runtime control for the fan:
             * - Function 0: Query supported functions (bitmask)
             * - Function 1: Set fan level (Arg3 = Buffer{level})
             * - Function 2: Get fan level (returns Buffer{level})
             */
            Method (_DSM, 4, Serialized)
            {
                // If not enough args were passed, return a safe default
                If (!CondRefOf (Arg0) || !CondRefOf (Arg1) || !CondRefOf (Arg2) || !CondRefOf (Arg3)) {
                    Return (Buffer (1) { 0x00 })
                }

                If (LEqual (Arg0, UUID)) {
                    Switch (ToInteger (Arg2))
                    {
                        Case (0) {
                            Return (Buffer (1) { 0x03 })
                        }
                        Case (1) {
                            If (SizeOf (Arg3) == 1) {
                                Store (DerefOf (Index (Arg3, 0)), STLV)
                                Return (Buffer (1) { 0x01 })
                            } Else {
                                Return (Buffer (1) { 0x00 })
                            }
                        }
                        Case (2) {
                            Local0 = Buffer (1) { 0x00 }
                            Store (STLV, Index (Local0, 0))
                            Return (Local0)
                        }
                        Default {
                            Return (Buffer (1) { 0x00 })
                        }
                    }
                }

                // UUID mismatch or no valid input — return 0
                Return (Buffer (1) { 0x00 })
            }
        }
    }
}
