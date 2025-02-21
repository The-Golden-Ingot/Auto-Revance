#!/bin/bash
# Twitter Piko
source src/build/utils.sh

# Patch Twitter Piko:
patch_piko () {
	dl_gh "revanced-cli" "revanced" "v4.6.0"
	get_patches_key "twitter-piko"
	local v apk_name
	if [[ "$1" == "latest" ]]; then
		v="latest" apk_name="stable"
	else
		v="prerelease" apk_name="beta"
	fi
	dl_gh "piko revanced-integrations" "crimera" "$v"
	get_apk "twitter-$apk_name" "x-corp/twitter/x-previously-twitter" \
		"bundle"
	
	# Generate arm64-v8a version with xxhdpi and English only
	split_editor "twitter-$apk_name" "twitter-arm64-v8a-$apk_name" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxxhdpi split_config.tvdpi split_config.ldpi split_config.ar split_config.de split_config.es split_config.fi split_config.fr split_config.hi split_config.hu split_config.in split_config.it split_config.ja split_config.ko split_config.ms split_config.nl split_config.pl split_config.pt split_config.ru split_config.sv split_config.th split_config.tr split_config.uk split_config.vi split_config.zh"
	patch "twitter-arm64-v8a-$apk_name" "piko"
	
	# Rename the output file
	mv ./release/twitter-arm64-v8a-$apk_name-piko.apk ./release/twitter-piko.apk
}

case "$1" in
	"prerelease"|"latest")
		patch_piko "$1"
		;;
esac