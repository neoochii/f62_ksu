#!/bin/bash
RDIR="$(pwd)"

export PLATFORM_VERSION=13
export ARCH=arm64
export ANDROID_MAJOR_VERSION=t

# Parse kernel name and version from neoochii_defconfig CONFIG_LOCALVERSION
# e.g. CONFIG_LOCALVERSION="-NeOoChIi-KeRnEl-v1.0" → NeOoChIi-KeRnEl / v1.0
DEFCONFIG_PATH="${RDIR}/arch/arm64/configs/neoochii_defconfig"
LOCALVERSION=$(grep 'CONFIG_LOCALVERSION=' "$DEFCONFIG_PATH" | cut -d'"' -f2 | sed 's/^-//')
KERNEL_NAME=$(echo "$LOCALVERSION" | grep -oP '^.*(?=-v[0-9])')
KERNEL_VER=$(echo "$LOCALVERSION"  | grep -oP 'v[0-9]+(\.[0-9]+)*.*')

if [ -z "$KERNEL_NAME" ] || [ -z "$KERNEL_VER" ]; then
    echo "[!] WARNING: Could not parse CONFIG_LOCALVERSION — falling back to defaults"
    KERNEL_NAME="NeOoChIi-KeRnEl"
    KERNEL_VER="unknown"
fi

# Fetch latest KernelSU-Next version from GitHub
KSU_VERSION=$(curl -s \
    "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/releases/latest" \
    | grep '"tag_name":' \
    | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')

[ -z "$KSU_VERSION" ] && KSU_VERSION="unknown"

# Build type selection menu
STOCK_BUILD=false

echo "================================"
echo " Select build type:"
echo "  1) KSU"
echo "  2) Stock"
echo "================================"
read -rp " Your choice [1]: " BUILD_CHOICE
BUILD_CHOICE=${BUILD_CHOICE:-1}

case "$BUILD_CHOICE" in
    1)
        echo "[*] Build type: KSU"
        ;;
    2)
        echo "[*] Build type: Stock"
        STOCK_BUILD=true
        ;;
    *)
        echo "[*] Invalid selection, defaulting to KSU"
        ;;
esac

# build dir
if [ ! -d "${RDIR}/build" ]; then
    mkdir -p "${RDIR}/build"
else
    rm -rf "${RDIR}/build"
    mkdir -p "${RDIR}/build"
fi

# build args
export ARGS="
-j$(nproc)
ARCH=arm64
"

# create flashable zip
build_zip() {
    echo "[+] Creating flashable zip..."

    if [ "$STOCK_BUILD" = true ]; then
        ZIP_NAME="${KERNEL_NAME}-f62-${KERNEL_VER}.zip"
    else
        ZIP_NAME="${KERNEL_NAME}-f62-${KERNEL_VER}-KernelSU-Next-${KSU_VERSION}.zip"
    fi

    rm -f "${RDIR}/buildzip/Image"
    cp "${RDIR}/arch/arm64/boot/Image" "${RDIR}/buildzip/"

    cd "${RDIR}/buildzip" || exit 1
    zip -r9 "../build/${ZIP_NAME}" ./*

    echo "[✓] Flashable zip created at build/${ZIP_NAME}"

    cd "${RDIR}" || exit 1
}

# build boot image
build_boot() {
    rm -f \
      "${RDIR}/AIK-Linux/split_img/boot.img-kernel" \
      "${RDIR}/AIK-Linux/boot.img" \
      "${RDIR}/build/boot.img"

    cp "${RDIR}/arch/arm64/boot/Image" \
       "${RDIR}/AIK-Linux/split_img/boot.img-kernel"

    echo "$BOARD" > "${RDIR}/AIK-Linux/split_img/boot.img-board"

    mkdir -p "${RDIR}/AIK-Linux/ramdisk"

    cd "${RDIR}/AIK-Linux" || exit 1
    ./repackimg.sh --nosudo
    mv image-new.img "${RDIR}/build/boot.img"

    cd "${RDIR}" || exit 1
}

# build odin tar
build_tar() {
    cd "${RDIR}/build" || exit 1

    tar -cvf "${KERNEL_NAME}-f62-${KERNEL_VER}-stock-One-UI.tar" boot.img

    echo -e "\n[i] Build Finished..!\n"

    cd "${RDIR}" || exit 1
}

# kernel build
build() {
    if [ "$STOCK_BUILD" = true ]; then
        echo "[!] Building STOCK + debug"
        make ${ARGS} neoochii_defconfig common.config debug.config
    else
        echo "[!] Building KSU + debug"
        make ${ARGS} neoochii_defconfig common.config ksu.config debug.config
    fi

    make ${ARGS} || exit 1
}

build
build_zip
build_boot
build_tar
