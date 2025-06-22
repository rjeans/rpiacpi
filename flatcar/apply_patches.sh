#!/bin/bash
set -euo pipefail

PATCH_DIR="patches"
SUBMODULE_DIR="scripts"

# Ensure required directories exist
if [ ! -d "$PATCH_DIR" ]; then
  echo "ERROR: Patch directory '$PATCH_DIR' not found."
  exit 1
fi

if [ ! -d "$SUBMODULE_DIR" ]; then
  echo "ERROR: Submodule directory '$SUBMODULE_DIR' not found."
  exit 1
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

if [ $PATCHES_APPLIED -gt 0 ]; then
  echo
  echo "==> Committing applied patch changes..."
  git commit -m "Apply $PATCHES_APPLIED patch(es) from ../$PATCH_DIR"
else
  echo
  echo "==> No new patches applied. No commit needed."
fi

echo
echo "==> Patch application complete."

