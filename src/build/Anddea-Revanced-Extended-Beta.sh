#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh

patch_youtube_rve() {
    # Download requirements
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    # Patch YouTube (Arm64-v8a only, but don't include in name):
    get_patches_key "youtube-rve-anddea"
    get_apk "com.google.android.youtube" "youtube" "youtube" "google-inc/youtube/youtube"
    # Generate rip-lib arguments to remove non-arm64-v8a architectures
    rip_libs=$(gen_rip_libs "armeabi-v7a" "x86" "x86_64")
    patch "youtube" "anddea" "inotia" "$rip_libs"
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac