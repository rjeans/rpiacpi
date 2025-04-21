#include <Uefi.h>
#include <Library/UefiDriverEntryPoint.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/BaseMemoryLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/DebugLib.h>
#include <Library/UefiLib.h>
#include <Protocol/AcpiTable.h>
#include <Protocol/LoadedImage.h>

// External ACPI AML blob and its dynamic length
extern unsigned char poefanssdt_aml_code[];
extern unsigned int  poefanssdt_aml_code_len;

STATIC EFI_ACPI_TABLE_PROTOCOL *mAcpiTableProtocol = NULL;
STATIC UINTN mInstalledTableKey = 0;



EFI_STATUS
EFIAPI
PoeFanDxeEntryPoint (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
)
{
  EFI_STATUS Status;

  DEBUG((DEBUG_INFO, "PoeFanDxe: EntryPoint started\n"));

  if (poefanssdt_aml_code == NULL || poefanssdt_aml_code_len == 0) {
    DEBUG((DEBUG_ERROR, "PoeFanDxe: Invalid ACPI table pointer or size.\n"));
    return EFI_INVALID_PARAMETER;
  }

  
  Status = gBS->LocateProtocol(&gEfiAcpiTableProtocolGuid, NULL, (VOID**)&mAcpiTableProtocol);
  if (EFI_ERROR(Status)) {
    DEBUG((DEBUG_ERROR, "PoeFanDxe: Failed to locate ACPI Table Protocol - %r\n", Status));
    return Status;
  }

  Status = mAcpiTableProtocol->InstallAcpiTable(
    mAcpiTableProtocol,
    poefanssdt_aml_code,
    poefanssdt_aml_code_len,
    &mInstalledTableKey
  );
  if (EFI_ERROR(Status)) {
    DEBUG((DEBUG_ERROR, "PoeFanDxe: Failed to install ACPI Table - %r\n", Status));
    return Status;
  }

  DEBUG((DEBUG_INFO, "PoeFanDxe: ACPI Table installed successfully, Key = %lu\n", mInstalledTableKey));

  

  return EFI_SUCCESS;
}
