#include <Uefi.h>
#include <Library/UefiDriverEntryPoint.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/DebugLib.h>
#include <Library/AcpiLib.h>

#include <Library/DxeServicesLib.h>
#include <Protocol/AcpiTable.h>

// Replace with your custom GUID (matches ACPI .INF GUID)
STATIC CONST EFI_GUID mMyAcpiTableGuid = {
  0x3A1F5B7C, 0x9D42, 0x4E8A, { 0xBF, 0x3E, 0x5C, 0x7D, 0x8A, 0x9E, 0x2F, 0x1B }
};

EFI_STATUS
EFIAPI
PoeDxeEntryPoint (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS Status;

  DEBUG((DEBUG_INFO, "Installing ACPI table from FV using GUID...\n"));

  Status = LocateAndInstallAcpiFromFvConditional(&mMyAcpiTableGuid, NULL);
  if (EFI_ERROR(Status)) {
    DEBUG((DEBUG_ERROR, "Failed to install ACPI table: %r\n", Status));
  } else {
    DEBUG((DEBUG_INFO, "ACPI table installed successfully\n"));
  }

  return Status;
}
