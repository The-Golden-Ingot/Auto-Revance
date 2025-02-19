#!/bin/bash
# Revanced Extended forked by Anddea build (ARM64-v8a only)
source src/build/utils.sh

patch_youtube_rve() {
    # Download requirements
    dl_gh "revanced-patches" "anddea" "prerelease"
    dl_gh "revanced-cli" "inotia00" "latest"

    # Patch YouTube
    get_patches_key "youtube-rve-anddea"
    get_apk "com.google.android.youtube" "youtube" "youtube" "google-inc/youtube/youtube"
    
    # Patch first (generates universal APK)
    patch "youtube" "anddea" "inotia"

    # Remove unwanted architectures from the patched APK
    echo "Removing non-ARM64-v8a libraries..."
    unzip -q "youtube.apk" -d youtube_unpacked
    rm -rf youtube_unpacked/lib/{armeabi-v7a,x86,x86_64}
    
    # Rebuild and sign the APK
    (cd youtube_unpacked && zip -qr ../youtube.apk .)
    rm -rf youtube_unpacked
    
    # Re-sign the APK (replace with your signing command)
    zipalign -p 4 youtube.apk youtube-aligned.apk
    apksigner sign --ks your_keystore.jks --ks-pass pass:your_password youtube-aligned.apk
    mv youtube-aligned.apk youtube.apk
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac
