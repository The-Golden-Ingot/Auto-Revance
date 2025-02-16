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
	
	# Steps 1-3: Get to the version-specific URL (keeping these for future reference)
	initial_page=$(req "https://adobe-lightroom-mobile.en.uptodown.com/android/download" -)
	
	variants_url=$(echo "$initial_page" | $pup '#variants-button attr{onclick}' | sed -n "s/.*'\(https[^']*\)'.*/\1/p")
	
	if [ -z "$variants_url" ]; then
		echo "Failed to extract variants URL"
		exit 1
	fi
	
	variants_page=$(req "$variants_url" -)
	
	version_url=$(echo "$variants_page" | $pup '.variant:nth-child(2) > .v-icon attr{onclick}' | sed -n "s/.*'\(https[^']*\)'.*/\1/p")
	
	if [ -z "$version_url" ]; then
		echo "Failed to extract version URL"
		exit 1
	fi
	
	# Step 4-7: Use the version-specific URL and download
	url="https://dw.uptodown.com/dwn/$(req "$version_url" - | $pup -p --charset utf-8 'button#detail-download-button attr{data-url}')"
	req "$url" "lightroom-beta.xapk"
	
	# Handle the XAPK bundle
	split_editor "lightroom-beta.xapk" "lightroom-beta"
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
