#! /usr/bin/env bash
set -euo pipefail

samloader() {
    local samloader_rs="https://github.com/topjohnwu/samloader-rs/releases/download/2.0.0/samloader-v2.0.0-linux-x86_64.tar.xz"
    local model="$1"
    local region="$2"

    wget -q "${samloader_rs}" -O /tmp/samloader_rs.tar.xz
    pushd /tmp; tar -xf samloader_rs.tar.xz; popd
    chmod +x /tmp/samloader
    /tmp/samloader download --model ${model} --region ${region} 
}

main_work() {
    local model="$1"
    local region="$2"
    local tmp_dir="$(pwd)/tmp"
    local out_dir="$(pwd)/out"

    # Create output directory
    mkdir ${out_dir}

    # Create temp dir
    mkdir ${tmp_dir}
    cd ${tmp_dir}

    # Fetch the firmware
    samloader ${model} ${region}

    # Unpack the firmware
    unzip ${model}*.zip
    rm -f BL* CSC* HOME_* CP* # delete everything except AP. 
    tar -xvf *.tar.md5 super.img.lz4
    lz4 -d super.img.lz4

    # Convert sparse image to raw image
    simg2img super.img super.img.raw

    # Unpack the super image
    lpunpack --partition=vendor super.img.raw

    # Cleanup and copy
    rm *.raw *.lz4 *.tar.md5 *.zip super.img
    mv ${tmp_dir}/vendor.img ${out_dir}
    cd ${out_dir}
    rm -rf ${tmp_dir}

    fsck.erofs --extract=vendor/ vendor.img; rm *.img
    echo "Current dir: $(pwd)"
    ls -laZ
}

main_work $1 $2
