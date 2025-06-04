make clean && make mrproper
@@ -1,5 +1,6 @@
#!/bin/bash
RDIR="$(pwd)"

export PLATFORM_VERSION=13
export ARCH=arm64
build(){Add commentMore actions
    export KSU_STATUS="ksu"
    make ${ARGS} neoochii_defconfig common.config ksu.config
    make ${ARGS} menuconfig
    make ${ARGS}
}
build
