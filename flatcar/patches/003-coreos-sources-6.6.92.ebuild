index 68ef261b9d..eb91fef32e 100644
--- a/sdk_container/src/third_party/coreos-overlay/sys-kernel/coreos-sources/coreos-sources-6.6.92.ebuild
+++ b/sdk_container/src/third_party/coreos-overlay/sys-kernel/coreos-sources/coreos-sources-6.6.92.ebuild
@@ -43,3 +43,10 @@ UNIPATCH_LIST="
        ${PATCH_DIR}/z0006-mtd-phram-slram-Disable-when-the-kernel-is-locked-do.patch \
        ${PATCH_DIR}/z0007-arm64-add-kernel-config-option-to-lock-down-when-in-.patch \
 "
+
+src_prepare() {
+  default
+
+  eapply -p1 "${FILESDIR}/0001-Raspberry-Pi-PoE-ACPI-Drivers.patch"
+}
+
