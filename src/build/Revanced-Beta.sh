#!/bin/bash
# Revanced build
source ./src/build/utils.sh
# Download requirements
revanced_dl(){
	dl_gh "revanced-patches" "revanced" "prerelease"
 	dl_gh "revanced-cli" "revanced" "latest"
}

patch_ggphotos() {
	revanced_dl
	# Patch Google photos:
	# Arm64-v8a
	get_patches_key "gg-photos"
	get_apk "com.google.android.apps.photos" "gg-photos-arm64-v8a-beta" "photos" "google-inc/photos/google-photos" "arm64-v8a" "nodpi"
	patch "gg-photos-arm64-v8a-beta" "revanced"
	# Armeabi-v7a
	get_patches_key "gg-photos"
	get_apk "com.google.android.apps.photos" "gg-photos-armeabi-v7a-beta" "photos" "google-inc/photos/google-photos" "armeabi-v7a" "nodpi"
	patch "gg-photos-armeabi-v7a-beta" "revanced"
}

patch_lightroom() {
	revanced_dl
	# Patch Lightroom:
	get_patches_key "lightroom"
	
	# Step 1: Visit initial download page and get version-specific URL
	initial_page=$(req "https://adobe-lightroom-mobile.en.uptodown.com/android/download" -)
	version_url=$(echo "$initial_page" | $pup '.variant:nth-child(2) > .v-icon attr{onclick}' | grep -o 'https://[^"]*')
	
	# Step 2: Visit version-specific page
	req "$version_url" - > /dev/null
	
	# Step 3: Wait required time before getting download button
	sleep 5  # Wait 5 seconds as specified
	
	# Step 4: Get final download URL from the button
	version_page=$(req "$version_url" -)
	download_url="https://dw.uptodown.com/dwn/$(echo "$version_page" | $pup 'button#detail-download-button attr{data-url}')"
	
	# Step 5: Download the APK
	req "$download_url" "lightroom-beta.apk"
	patch "lightroom-beta" "revanced"
}

patch_soundcloud() {
	revanced_dl
	# Patch SoundCloud:
	get_patches_key "soundcloud"
	get_apk "com.soundcloud.android" "soundcloud-beta" "soundcloud-soundcloud" "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "Bundle_extract"
	split_editor "soundcloud-beta" "soundcloud-beta"
	patch "soundcloud-beta" "revanced"
}

case "$1" in
    "ggphotos")
        patch_ggphotos
        ;;
    "lightroom")
        patch_lightroom
        ;;
    "soundcloud")
        patch_soundcloud
        ;;
esac