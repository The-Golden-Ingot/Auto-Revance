#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh

patch_youtube_rve() {
    # Download requirements
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    # Patch YouTube (arm64-v8a only):
    get_patches_key "youtube-rve-anddea"
    get_apk "com.google.android.youtube" "youtube" "youtube" "google-inc/youtube/youtube" "arm64-v8a" "nodpi"
    patch "youtube" "anddea" "inotia"
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac
