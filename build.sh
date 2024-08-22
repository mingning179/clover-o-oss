#!/bin/bash

echo '开始配置'
mkdir -p out
if [ $? -ne 0 ]; then
    echo '创建out目录失败'
    exit 1
fi
# 测试编译，不会因为警告而停止
export testBuild=true

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=${PWD}/toolchain/bin/aarch64-linux-android-

#这里定义一些/proc/version中的信息
#export KBUILD_BUILD_USER=HELLOBOY2024
#export KBUILD_BUILD_HOST=HELLOHOST2024
#export KBUILD_BUILD_VERSION=HELLOVERSION2024
#export KBUILD_BUILD_TIMESTAMP=2024-01-01


#export DTC_EXT=dtc
#set CONFIG_BUILD_ARM64_DT_OVERLAY=y
echo "CROSS_COMPILE=$CROSS_COMPILE"
echo "DTC_EXT=$DTC_EXT"
echo "CONFIG_BUILD_ARM64_DT_OVERLAY=$CONFIG_BUILD_ARM64_DT_OVERLAY"

# 清理之前的编译结果
make O=out clean
if [ $? -ne 0 ]; then
    echo '清理编译结果失败'
    exit 1
fi

# 配置编译
make O=out clover-perf_defconfig
if [ $? -ne 0 ]; then
    echo '配置编译失败'
    exit 1
fi

# 进行编译
make -j$(nproc) O=out 2>&1 | tee kernel.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo '编译失败'
    exit 1
fi

echo '编译完成'
#调用 deploy.sh
./deploy.sh