#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_SOURCE="${1:-}"
KERNEL_DEFCONFIG="${2:-}"
KERNEL_OUT="${KERNEL_OUT:-${SCRIPT_DIR}/out/kernel-r8q}"
KERNEL_CC="${KERNEL_CC:-clang}"
KERNEL_CROSS_COMPILE="${KERNEL_CROSS_COMPILE:-}"
KERNEL_LLVM="${KERNEL_LLVM:-}"
KERNEL_JOBS="${KERNEL_JOBS:-$(nproc)}"

usage() {
    printf 'Usage: %s <android-kernel-source> <variant-defconfig>\n' "${0##*/}"
    printf 'Example: KERNEL_CROSS_COMPILE=/toolchain/bin/aarch64-linux-android- %s /src/kernel vendor/r8q_eur_open_defconfig\n' "${0##*/}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ -z "$KERNEL_SOURCE" || -z "$KERNEL_DEFCONFIG" ]]; then
    usage >&2
    exit 2
fi

if [[ -z "$KERNEL_CROSS_COMPILE" && -z "$KERNEL_LLVM" ]]; then
    echo "Set KERNEL_CROSS_COMPILE or KERNEL_LLVM for the kernel's matching toolchain." >&2
    exit 1
fi

if [[ ! -f "${KERNEL_SOURCE}/Makefile" ]]; then
    echo "Not an Android kernel source tree: $KERNEL_SOURCE" >&2
    exit 1
fi

if [[ "$KERNEL_DEFCONFIG" == *..* || ! -f "${KERNEL_SOURCE}/arch/arm64/configs/${KERNEL_DEFCONFIG}" ]]; then
    echo "Defconfig not found under arch/arm64/configs: $KERNEL_DEFCONFIG" >&2
    exit 1
fi

if [[ ! "$KERNEL_JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "KERNEL_JOBS must be a positive integer." >&2
    exit 1
fi

KERNEL_SOURCE="$(realpath -- "$KERNEL_SOURCE")"
KERNEL_OUT="$(realpath -m -- "$KERNEL_OUT")"
mkdir -p -- "$KERNEL_OUT"

make_args=(-C "$KERNEL_SOURCE" "O=${KERNEL_OUT}" ARCH=arm64)
if [[ -n "$KERNEL_CROSS_COMPILE" ]]; then
    make_args+=("CROSS_COMPILE=${KERNEL_CROSS_COMPILE}")
fi
if [[ -n "$KERNEL_CC" ]]; then
    make_args+=("CC=${KERNEL_CC}")
fi
if [[ -n "$KERNEL_LLVM" ]]; then
    make_args+=("LLVM=${KERNEL_LLVM}")
fi

make "${make_args[@]}" "$KERNEL_DEFCONFIG"
"${KERNEL_SOURCE}/scripts/kconfig/merge_config.sh" \
    -m \
    -O "$KERNEL_OUT" \
    "${KERNEL_OUT}/.config" \
    "${SCRIPT_DIR}/kernel/halium.config"
make "${make_args[@]}" olddefconfig

while IFS= read -r option; do
    [[ -z "$option" ]] && continue
    if [[ "$option" == \#* && "$option" != \#\ CONFIG_*' is not set' ]]; then
        continue
    fi
    if [[ "$option" == \#\ CONFIG_*' is not set' ]]; then
        symbol="${option#\# }"
        symbol="${symbol% is not set}"
    else
        symbol="${option%%=*}"
    fi
    if ! grep -Eq "^(# )?${symbol}(=| is not set$)" "${KERNEL_OUT}/.config"; then
        echo "Skipping Halium setting unavailable in this kernel: $symbol" >&2
        continue
    fi
    if ! grep -Fxq "$option" "${KERNEL_OUT}/.config"; then
        echo "Kernel config does not satisfy required Halium setting: $option" >&2
        exit 1
    fi
done < "${SCRIPT_DIR}/kernel/halium.config"

make "${make_args[@]}" -j"$KERNEL_JOBS" Image.gz dtbs modules

printf 'Kernel build output: %s\n' "$KERNEL_OUT"
