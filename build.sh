#!/bin/bash
RDIR="$(pwd)"

export PLATFORM_VERSION=13
export ARCH=arm64
export ANDROID_MAJOR_VERSION=t
MODEL="GalaxyF62"
BUILD_KERNEL_VERSION="V6.0"

# Check for debug flag
DEBUG_BUILD=false
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--debug)
            DEBUG_BUILD=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

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

    ZIP_NAME="${MODEL}-${BUILD_KERNEL_VERSION}.zip"

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

    tar -cvf "${MODEL}-${BUILD_KERNEL_VERSION}-stock-One-UI.tar" boot.img

    echo -e "\n[i] Build Finished..!\n"

    cd "${RDIR}" || exit 1
}

# kernel build
build() {
    if [ "$DEBUG_BUILD" = true ]; then
        echo "[!] Building with all configs + debug.config"
        make ${ARGS} neoochii_defconfig common.config ksu.config debug.config
    else
        echo "[!] Building with all configs"
        make ${ARGS} neoochii_defconfig common.config ksu.config
    fi

    make ${ARGS} || exit 1
}

build
build_zip
build_boot
build_tar
