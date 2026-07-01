#! /usr/bin/env bash
set -euo pipefail

main_work() {
    local url="$1"
    local tmp_dir="/tmp/action_sw"

    # Create temp dir
    mkdir -p ${tmp_dir}
    cd ${tmp_dir}

    # Fetch the firmware
    wget "$url" -O "AP.zip"

    # Unpack the firmware
    unzip "AP.zip"
    tar -xvf *.tar.md5
    lz4 -d super.img.lz4

    # Convert sparse image to raw image
    simg2img super.img super.img.raw

    # Unpack the super image
    lpunpack --partition=vendor super.img

    # Cleanup and copy
    rm *.raw *.lz4 *.tar.md5 *.zip super.img
    cd -
    mv ${tmp_dir}/vendor.img ./out
    rm -rf ${tmp_dir}

    cd out; fsck.erofs --extract=vendor/ vendor.img; rm *.img; cd -
}

main_work "$1"
