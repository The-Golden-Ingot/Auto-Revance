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
	get_apk "com.twitter.android" "twitter" "twitter" "x-corp/twitter/x-previously-twitter" "Bundle_extract"
	# Only build arm64-v8a version but name it without architecture
	split_editor "twitter" "twitter" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxhdpi split_config.tvdpi"
	patch "twitter" "piko"
}

case "$1" in
    "prerelease"|"latest")
        patch_twitter_piko "$1"
        ;;
esac
