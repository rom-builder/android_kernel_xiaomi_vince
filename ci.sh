#!/bin/bash

# What CI Script
# Copyright (C) 2019 Raphiel Rollerscaperers (raphielscape)
# Copyright (C) 2019 Rama Bondan Prakoso (rama982) 
# Copyright (C) 2019-2023 Keternal (KeternalGithub@163.com)
# Copyright (C) 2020 StarLight5234
# Copyright (C) 2021-22 GhostMaster69-dev
# SPDX-License-Identifier: GPL-3.0-or-later

#
# Telegram FUNCTION begin
#

git clone https://github.com/fabianonline/telegram.sh telegram

TELEGRAM_ID=-1001868141906
TELEGRAM=telegram/telegram
BOT_API_KEY=963254339:AAGF81vp_kdZ-eXEV_xoOuJDgytQpont9y4
TELEGRAM_TOKEN=${BOT_API_KEY}

export TELEGRAM_TOKEN

# Push kernel installer to channel
function push_package() {
	JIP="Nito-Kernel-$ZIP_VERSION-$BUILD_TYPE-$BUILD_POINT.zip"
	curl -F document=@$JIP  "https://api.telegram.org/bot$BOT_API_KEY/sendDocument" \
	     -F chat_id="$TELEGRAM_ID"
}

function push_md5sum() {
	JIP="md5sum_$(git log --pretty=format:'%h' -1).md5sum"
	curl -F document=@$JIP  "https://api.telegram.org/bot$BOT_API_KEY/sendDocument" \
	     -F chat_id="$TELEGRAM_ID"
}

function push_dtb() {
        JIP="out/arch/arm64/boot/dts/qcom/msm8953-qrd-sku3-vince.dtb"
        curl -F document=@$JIP  "https://api.telegram.org/bot$BOT_API_KEY/sendDocument" \
             -F chat_id="$TELEGRAM_ID"
}

# Send the info up
function tg_channelcast() {
	"${TELEGRAM}" -c ${TELEGRAM_ID} -H \
		"$(
			for POST in "${@}"; do
				echo "${POST}"
			done
		)"
}

function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot$BOT_API_KEY/sendMessage" \
		-d "parse_mode=markdown" \
		-d text="${1}" \
		-d chat_id="$TELEGRAM_ID" \
		-d "disable_web_page_preview=true"
}

# Send sticker
function tg_sendstick() {
	curl -s -X POST "https://api.telegram.org/bot$BOT_API_KEY/sendSticker" \
		-d sticker="CAADBQADKgADxKPLIvWZnUrOEg0NAg" \
		-d chat_id="$TELEGRAM_ID" >> /dev/null
}

# Fin prober
function fin() {
	tg_channelcast "<b>Build done!</b>" \
	"Use $(($DIFF / 60)) min $(($DIFF % 60)) sec!" \
	"Make sure you are using Magisk 20.3+!"
}

# Errored prober
function finerr() {
	tg_channelcast "<b>Build fail...</b>" \
	"Check build log to fix compile error!"
	exit 1
}

#
# Telegram FUNCTION end
#

# Build Enviroment

# Build Time Setup
export DATE=`date`
export BUILD_START=$(date "+%s")

# Customize Build Host and User
export KBUILD_BUILD_USER="Shining Star"
export KBUILD_BUILD_HOST="CircleCI"

# Defind Kernel Binary
export IMG=${PWD}/out/arch/arm64/boot/Image.gz-dtb

# Used for Telegram
export VERSION_TG="WHAT"
export ZIP_VERSION="WHAT"
export BUILD_TYPE="WHAT"

# Telegram Stuff

tg_sendstick

tg_channelcast "<b>Nito Kernel $VERSION_TG</b> new build!" \
		"Stage: <b>WHAT</b>" \
		"From <b>Nito Kernel GN</b>" \
		"Under commit <b>$(git log --pretty=format:'%h' -1)</b>"

# Clone Toolchain
git clone -b release/15.x --depth=1 https://gitlab.com/GhostMaster69-dev/cosmic-clang.git ${PWD}/Toolchain
export PATH="${PWD}/Toolchain/bin:$PATH"

# Customize Compiler Name
export KBUILD_COMPILER_STRING=$(${PWD}/Toolchain/bin/clang -v 2>&1 | grep ' version ' | sed 's/([^)]*)[[:space:]]//' | sed 's/([^)]*)//')

# Compile Kernel
make O=out LLVM=1 LLVM_IAS=1 defconfig -j$(grep -c '^processor' /proc/cpuinfo) || finerr
make O=out LLVM=1 LLVM_IAS=1 -j$(grep -c '^processor' /proc/cpuinfo) || finerr

# Calc Build Used Time
export BUILD_END=$(date "+%s")
export DIFF=$(($BUILD_END - $BUILD_START))
export BUILD_POINT=$(git log --pretty=format:'%h' -1)

# Packing
cp $IMG Flasher/
cd Flasher/
zip -r9 -9 "Nito-Kernel-$ZIP_VERSION-$BUILD_TYPE-$BUILD_POINT.zip" .
md5sum Nito-Kernel-$ZIP_VERSION-$BUILD_TYPE-$BUILD_POINT.zip >> "md5sum_$(git log --pretty=format:'%h' -1).md5sum"

# Push
push_package
push_md5sum
cd ..
# push_dtb
fin
