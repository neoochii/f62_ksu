make clean && make mrproper
#!/bin/bash
RDIR="$(pwd)"

export PLATFORM_VERSION=13
export ARCH=arm64
export ANDROID_MAJOR_VERSION=t
MODEL="GalaxyF62"
BUILD_KERNEL_VERSION="V3"

# Check for -d flag
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

#init ksu next
git submodule init && git submodule update
# Install requirements
if [ ! -f ".requirements" ]; then
    sudo apt update && sudo apt install -y git device-tree-compiler lz4 xz-utils zlib1g-dev openjdk-17-jdk gcc g++ python3 python-is-python3 p7zip-full android-sdk-libsparse-utils erofs-utils \
        default-jdk git gnupg flex bison gperf build-essential zip curl libc6-dev libncurses-dev libx11-dev libreadline-dev libgl1 libgl1-mesa-dev \
        python3 make sudo gcc g++ bc grep tofrodos python3-markdown libxml2-utils xsltproc zlib1g-dev python-is-python3 libc6-dev libtinfo6 \
        make repo cpio kmod openssl libelf-dev pahole libssl-dev --fix-missing && wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb && sudo dpkg -i libtinfo5_6.3-2ubuntu0.1_amd64.deb && touch .requirements
fi

#build dir
if [ ! -d "${RDIR}/build" ]; then
    mkdir -p "${RDIR}/build"
else
    rm -rf "${RDIR}/build" && mkdir -p "${RDIR}/build"
fi 

# main variables
export ARGS="
-j$(nproc)
ARCH=arm64
"
# create flashable zip from buildzip folder

build_zip() {
 
 
  echo "[+] Creating flashable zip..."

 ZIP_NAME="KernelSU-Next-${MODEL}-${BUILD_KERNEL_VERSION}.zip"
 rm -f  ${RDIR}/buildzip/Image
 cp "${RDIR}/arch/arm64/boot/Image"  "${RDIR}/buildzip/"
 cd "${RDIR}/buildzip"
 zip -r9 "../build/${ZIP_NAME}" ./*
 echo "[✓] Flashable zip created at build/${ZIP_NAME}"
  cd "${RDIR}"
}


#build boot.img
build_boot() {    
    rm -f ${RDIR}/AIK-Linux/split_img/boot.img-kernel ${RDIR}/AIK-Linux/boot.img ${RDIR}/build/boot.img
    cp "${RDIR}/arch/arm64/boot/Image" ${RDIR}/AIK-Linux/split_img/boot.img-kernel
    echo $BOARD > ${RDIR}/AIK-Linux/split_img/boot.img-board
    mkdir -p ${RDIR}/AIK-Linux/ramdisk
    cd ${RDIR}/AIK-Linux && ./repackimg.sh --nosudo && mv image-new.img ${RDIR}/build/boot.img
}

#build odin flashable tar
build_tar(){
    cd ${RDIR}/build
    tar -cvf "KernelSU-Next-${MODEL}-${BUILD_KERNEL_VERSION}-stock-One-UI.tar" boot.img 
    echo -e "\n[i] Build Finished..!\n" && cd ${RDIR}
}

# building function
build() {
    if [ "$DEBUG_BUILD" = true ]; then
        echo "[!] Building with debug.config (permissive)"
        make ${ARGS} neoochii_defconfig common.config ksu.config debug.config
    else
        echo "[!] Building without debug.config"
        make ${ARGS} neoochii_defconfig common.config ksu.config
    fi
    
    make ${ARGS} menuconfig || true
    make ${ARGS} || exit 1
}

build
build_zip
build_boot
build_tar
