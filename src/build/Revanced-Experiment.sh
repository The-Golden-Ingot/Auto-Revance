#!/bin/bash
# ReVanced Experiments build 
source src/build/utils.sh

patch_instagram_rve() {
    # Download requirements
    dl_gh "ReVancedExperiments" "Aunali321" "latest"
    dl_gh "revanced-cli" "revanced" "latest"

    get_patches_key "instagram-revanced-experiments"
    get_apk "com.instagram.android" "instagram.apk" "Instagram" "instagram/instagram-instagram" \
            "apk" "universal" "nodpi"
    patch "instagram" "revanced-experiments"
}

case "$1" in
    "instagram-rve")
        patch_instagram_rve
        ;;
esac