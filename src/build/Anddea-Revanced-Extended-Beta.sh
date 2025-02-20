#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh

patch_youtube_rve() {
    # Download requirements
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    # Patch YouTube (arm64-v8a only):
    get_patches_key "youtube-rve-anddea"
    get_apk "com.google.android.youtube" "youtube-beta" "youtube" "google-inc/youtube/youtube"
    
    # Generate arguments to remove architectures and common DPIs
    rip_libs=$(gen_rip_libs armeabi-v7a x86 x86_64)
    rip_dpi="--rip-dpi mdpi --rip-dpi hdpi --rip-dpi xhdpi --rip-dpi xxxhdpi"
    
    # Only generate arm64-v8a version with xxhdpi resources
    split_arch "youtube-beta" "anddea" "$rip_libs $rip_dpi"
    
    # Rename the output file
    mv ./release/youtube-beta-arm64-v8a-anddea.apk ./release/youtube-anddea.apk
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac