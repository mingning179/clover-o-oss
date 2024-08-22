#!/bin/bash

handle_error() {
    if [ $? -ne 0 ]; then
        echo "$1"
        exit 1
    fi
}

create_release_dir() {
    rm -rf release
    handle_error '删除release目录失败'

    mkdir -p release
    handle_error '创建release目录失败'
}

copy_files() {
    cp out/arch/arm64/boot/Image.gz-dtb release/Image.gz-dtb
    handle_error '复制Image.gz-dtb失败'

    cp pre_boot/boot.img release/boot.img
    handle_error '复制boot.img失败'
}

update_boot_img() {
    cd release
    handle_error '进入release目录失败'

    abootimg -u boot.img -k Image.gz-dtb
    handle_error '更新boot.img失败'

    rm -rf Image.gz-dtb
    handle_error '删除Image.gz-dtb失败'

    newname=boot-$(date +%Y%m%d%H%M).img
    mv boot.img $newname
    handle_error '重命名boot.img失败'

    echo '打包完成 path = '$(pwd)/$newname
}

fastboot_process() {
    echo '设备已经连接'
    fastboot flash boot $newname
    handle_error '刷入boot.img失败'

    fastboot reboot
    handle_error '重启设备失败'

    echo '刷入boot.img成功'
    echo '设备正在重启,请稍等...重启成功还有后续操作'
    adb wait-for-device
    cd ../
    adb push out/drivers/staging/qcacld-3.0/wlan.ko /data/local/tmp/wlan.ko
    adb shell mv /data/local/tmp/wlan.ko /persist/wlan.ko
    adb shell rm -rf /data/local/tmp/wlan.ko
    handle_error '刷入wlan.ko失败,请手动刷入wlan.ko到/perist/wlan.ko'
    echo '刷入wlan.ko成功,等待设备重启完成'
    adb reboot
}

adb_process() {
    echo '设备未连接，尝试通过adb进入fastboot模式'
    adb reboot bootloader
    handle_error '通过adb进入fastboot模式失败'

    sleep 5
    if fastboot devices | grep -q 'fastboot'; then
        fastboot_process
    else
        echo '无法进入fastboot模式，请手动检查设备连接'
        exit 1
    fi
}

main() {
    echo '开始打包'
    create_release_dir
    copy_files
    update_boot_img

    if fastboot devices | grep -q 'fastboot'; then
        fastboot_process
    else
        adb_process
    fi
}

main