#!/bin/bash
# ReVanced Experiments build 
source src/build/utils.sh

patch_instagram_rve() {
    # Download requirements
    dl_gh "ReVancedExperiments" "Aunali321" "latest"
    dl_gh "revanced-cli" "revanced" "latest"

    # Patch Instagram:
    get_patches_key "instagram-revanced-experiments"
    get_apk "com.instagram.android" "instagram" "instagram-instagram" "instagram/instagram-instagram/instagram-instagram" "Bundle_extract"
    
    # Merge the split APK, keeping only arm64-v8a and xxhdpi
    split_editor "instagram" "instagram-merged" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxxhdpi split_config.tvdpi split_config.ldpi"
    
    # Patch the merged APK
    patch "instagram-merged" "revanced-experiments"
    
    # Rename the final output file
    mv ./release/instagram-merged-revanced-experiments.apk ./release/instagram-revanced-experiments.apk
}

case "$1" in
    "instagram-rve")
        patch_instagram_rve
        ;;
esac
