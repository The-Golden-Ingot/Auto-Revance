#!/bin/bash
# ReVanced Experiments build 
source src/build/utils.sh

patch_instagram_rve() {
    # Download requirements
    dl_gh "ReVancedExperiments" "Aunali321" "latest"
    dl_gh "revanced-cli" "revanced" "latest"

    # Patch Instagram:
    get_patches_key "instagram-revanced-experiments"
    get_apk "com.instagram.android" "instagram" "instagram-instagram" "instagram/instagram-instagram/instagram-instagram" "Bundle_extract" "arm64-v8a" "nodpi"
    
    # Merge the already optimized split APK (arm64-v8a and nodpi)
    split_editor "instagram" "instagram-merged" "exclude" ""
    
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
