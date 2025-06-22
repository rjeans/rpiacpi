
#include <IndustryStandard/Bcm2711.h>


DefinitionBlock ("PoeFan.asl", "SSDT", 2, "RPIFDN", "RPIPOEFN", 2)
{
  // Declare external objects here
  External (\_SB.GDV0.RPIQ, DeviceObj)

  Scope (_SB)
  {
    Device (POEH)
    {
      Name (_HID, "POEF0001")           // Match to your PWM ACPI driver
      Name (_UID, 0)
      Name (_CCA, 1)

      Name (_DSD, Package ()
      {
        ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package ()
        {
          // Bind to mailbox controller (firmware channel)
          Package () { "mboxes", Package () { \_SB.GDV0.RPIQ } },

          // Compatible string for binding to the driver
          Package () { "compatible", "rpi-pwm-poe" }
        }
      })
    }

    Device (FAN0)
    {
      Name (_HID, "PWMF0001")          // Custom HID for pwm-fan
      Name (_UID, 0)
      Name (_CCA, 1)

      Name (_DSD, Package ()
      {
        ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package ()
        {
          // Link to the ACPI PWM device (e.g., your poe-fan PWM device)
          Package () { "pwms", Package () { \_SB.POEH, 0, 80000 } }, // PWM index 0, period=80000 ns

          Package () { "cooling-levels", Package () { 0, 64, 128, 192, 255 } },

          // Let pwm-fan driver bind to it
          Package () { "compatible", "pwm-fan" }
        }
      })
    }

    Device (RPEC)
    {
      Name (_HID, "RPIT0001")
      Name (_CCA, 1)

      Name (_DSD, Package ()
      {
        ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package ()
        {
          Package () { "active-trip-temps", Package () { 65000, 70000, 75000, 80000 } },
          Package () { "active-trip-hysteresis", Package () { 5000, 4999, 4999, 4999 } },
          Package () { "cooling-min-states", Package () { 1, 2, 3, 4 } },
          Package () { "cooling-max-states", Package () { 1, 2, 3, 4 } },
          Package () { "cooling-device", Package () { \_SB.FAN0 } }
        }
      })

      // All temps are in tenths of K (e.g., 2732 is the min temp in Linux (0°C))
      Method (_TMP, 0, Serialized)
      {
        OperationRegion (TEMS, SystemMemory, THERM_SENSOR, 0x8)
        Field (TEMS, DWordAcc, NoLock, Preserve)
        {
          TMPS, 32
        }
        Return (((410040 - ((TMPS & 0x3FF) * 487)) / 100) + 2732)
      }
    }
  }
}
