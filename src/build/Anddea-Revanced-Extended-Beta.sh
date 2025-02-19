#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh

patch_youtube_rve() {
    # Download requirements
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    # Patch YouTube (Arm64-v8a only, but don't include in name):
    get_patches_key "youtube-rve-anddea"
    get_apk "com.google.android.youtube" "youtube" "youtube" "google-inc/youtube/youtube" "Bundle_extract"
    # Only build arm64-v8a version and remove unnecessary DPI resources
    split_editor "youtube" "youtube" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxhdpi split_config.tvdpi"
    patch "youtube" "anddea" "inotia"
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac