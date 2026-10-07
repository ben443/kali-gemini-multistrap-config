#!/usr/bin/env bash

set -Eeuo pipefail

HALIUM_SOURCE="${1:-}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    printf 'Usage: %s <Halium-11.0-source-tree>\n' "${0##*/}"
    exit 0
fi

if [[ -z "$HALIUM_SOURCE" ]]; then
    echo "Provide a populated Halium-11.0 source tree." >&2
    exit 2
fi

HALIUM_SOURCE="$(realpath -- "$HALIUM_SOURCE")"
if [[ ! -f "${HALIUM_SOURCE}/build/envsetup.sh" ||
      ! -x "${HALIUM_SOURCE}/hybris-patches/apply-patches.sh" ||
      ! -d "${HALIUM_SOURCE}/device/samsung/r8q" ]]; then
    echo "Source tree must contain Halium build files and device/samsung/r8q." >&2
    exit 1
fi

if [[ ! -d "${HALIUM_SOURCE}/vendor/samsung/r8q" ]]; then
    echo "Samsung vendor files are missing from the Halium source tree." >&2
    echo "Add verified SM-G781B vendor files before building." >&2
    exit 1
fi

(
    cd "$HALIUM_SOURCE"
    # shellcheck source=/dev/null
    source build/envsetup.sh
    breakfast r8q
    ./hybris-patches/apply-patches.sh --mb
    export USE_HOST_LEX=yes
    mka mkbootimg hybris-boot systemimage
)
