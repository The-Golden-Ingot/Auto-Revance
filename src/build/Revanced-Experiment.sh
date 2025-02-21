#!/bin/bash
# ReVanced Experiments build 
source src/build/utils.sh

patch_instagram_rve() {
    set -x  # Enable debug mode
    
    green_log "[+] Downloading requirements"
    dl_gh "ReVancedExperiments" "Aunali321" "latest"
    dl_gh "revanced-cli" "revanced" "latest"

    green_log "[+] Getting patches"
    get_patches_key "instagram-revanced-experiments"
    
    green_log "[+] Downloading Instagram APK"
    get_apk "com.instagram.android" "instagram.apk" "Instagram" "instagram/instagram-instagram" \
            "apk" "universal" "nodpi"
    
    green_log "[+] Patching Instagram"
    patch "instagram" "revanced-experiments"
    set +x  # Disable debug mode
}

case "$1" in
    "instagram-rve")
        patch_instagram_rve
        ;;
esac