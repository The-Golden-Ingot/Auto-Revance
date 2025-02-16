#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh

patch_youtube_rve() {
    # Download requirements
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    # Patch YouTube:
    get_patches_key "youtube-rve-anddea"
    get_apk "com.google.android.youtube" "youtube-beta" "youtube" "google-inc/youtube/youtube"
    patch "youtube-beta" "anddea" "inotia"

    # Patch YouTube Arm64-v8a only:
    get_patches_key "youtube-rve-anddea"
    split_arch "youtube-beta" "anddea" "$(gen_rip_libs armeabi-v7a x86_64 x86)"
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac
