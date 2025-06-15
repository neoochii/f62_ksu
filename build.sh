make clean && make mrproper
@@ -1,8 +1,24 @@
#!/bin/bash
RDIR="$(pwd)"


export PLATFORM_VERSION=13
export ARCH=arm64
export ANDROID_MAJOR_VERSION=t


#main variables
export ARGS="
-j$(nproc)
ARCH=arm64

"
#building function
build(){
    make ${ARGS} neoochii_defconfig common.config ksu.config
    make ${ARGS} menuconfig
	make ${ARGS} || exit 1
}

build
