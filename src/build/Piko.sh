#!/bin/bash
# Twitter Piko
source src/build/utils.sh

patch_twitter_piko() {
	dl_gh "revanced-cli" "revanced" "v4.6.0"
	get_patches_key "twitter-piko"
	local v apk_name
	if [[ "$1" == "latest" ]]; then
		v="latest" apk_name="stable"
	else
		v="prerelease" apk_name="beta"
	fi
	dl_gh "piko revanced-integrations" "crimera" "$v"
	
	# Patch Twitter (arm64-v8a only):
	get_patches_key "twitter-piko"
	get_apk "com.twitter.android" "twitter-beta" "twitter" "x-corp/twitter/x-previously-twitter" "Bundle_extract"
	
	# Only generate arm64-v8a version and keep xxhdpi (closest to 441 DPI)
	split_editor "twitter-beta" "twitter-beta" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxxhdpi split_config.tvdpi"
	patch "twitter-beta" "piko"
	
	# Rename the output file
	mv ./release/twitter-beta-piko.apk ./release/twitter-piko.apk
}

case "$1" in
    "prerelease"|"latest")
        patch_twitter_piko "$1"
        ;;
esac
