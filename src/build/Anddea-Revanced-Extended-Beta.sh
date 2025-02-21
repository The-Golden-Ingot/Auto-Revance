#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh

patch_youtube_rve() {
    set -x  # Enable debug mode
    
    green_log "[+] Downloading YouTube APK"
    get_apk "com.google.android.youtube" "youtube-beta.apk" "youtube" "google-inc/youtube" \
            "apk" "arm64-v8a" "xxhdpi" "" "android11"
    
    green_log "[+] Downloading requirements"
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    green_log "[+] Getting patches"
    get_patches_key "youtube-rve-anddea"
    
    green_log "[+] Generating lib arguments"
    rip_libs=$(gen_rip_libs armeabi-v7a x86 x86_64)
    
    green_log "[+] Setting DPI arguments"
    rip_dpi="--rip-dpi mdpi --rip-dpi hdpi --rip-dpi xhdpi --rip-dpi xxxhdpi --rip-dpi tvdpi --rip-dpi sw600dp --rip-dpi sw720dp --rip-dpi watch"
    
    green_log "[+] Processing architecture split"
    split_arch "youtube-beta" "anddea" "$rip_libs $rip_dpi"
    
    green_log "[+] Renaming output file"
    mv ./release/youtube-beta-arm64-v8a-anddea.apk ./release/youtube-anddea.apk
    set +x  # Disable debug mode
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac