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
    # Use the actual output APK name from the patch step
    INPUT_APK="./release/youtube-anddea.apk"
    OUTPUT_APK="./release/youtube-arm64.apk"
    
    # Ensure APK exists
    if [ ! -f "$INPUT_APK" ]; then
        echo "Error: Patched APK not found at $INPUT_APK"
        exit 1
    fi

    # Unpack, remove unwanted libs, repack
    unzip -q "$INPUT_APK" -d youtube_unpacked
    rm -rf youtube_unpacked/lib/{armeabi-v7a,x86,x86_64}
    
    # Rebuild and sign the APK
    (cd youtube_unpacked && zip -qr "../$OUTPUT_APK" .)
    rm -rf youtube_unpacked
    
    # Re-sign the APK (requires Android Build Tools)
    if command -v zipalign &> /dev/null && command -v apksigner &> /dev/null; then
        zipalign -p 4 "$OUTPUT_APK" "${OUTPUT_APK%.apk}-aligned.apk"
        apksigner sign --ks your_keystore.jks --ks-pass pass:your_password "${OUTPUT_APK%.apk}-aligned.apk"
        mv "${OUTPUT_APK%.apk}-aligned.apk" "$OUTPUT_APK"
    else
        echo "Error: zipalign/apksigner not found. Install Android Build Tools."
        exit 1
    fi
}

case "$1" in
    "youtube-rve")
        patch_youtube_rve
        ;;
esac
