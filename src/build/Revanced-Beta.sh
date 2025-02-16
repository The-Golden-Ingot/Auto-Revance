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
	
	# Get versions page directly
	versions_page=$(req "https://adobe-lightroom-mobile.en.uptodown.com/android/versions" -)
	
	# Extract first APK version URL using data-url attribute and prepend domain
	version_url="https://adobe-lightroom-mobile.en.uptodown.com$(echo "$versions_page" | $pup '.versions .content div.type.apk:nth-of-type(1) attr{data-url}')"
	
	if [ -z "$version_url" ]; then
		echo "Failed to extract version URL"
		exit 1
	fi
	
	echo "Version URL: $version_url"
	
	# Download the specific version's detailed page and extract the final download URL from the button
	download_page=$(req "$version_url" -)
	
	# Debug: Save the download page HTML to inspect it
	echo "$download_page" > download_page.html
	
	# Try different selectors for the download button
	download_url=$(echo "$download_page" | $pup 'a#detail-download-button attr{data-url}')
	if [ -z "$download_url" ]; then
		download_url=$(echo "$download_page" | $pup '[data-url]:contains("Download") attr{data-url}')
	fi
	
	if [ -z "$download_url" ]; then
		echo "Failed to extract download URL"
		echo "Download page saved to download_page.html for inspection"
		exit 1
	fi
	
	echo "Download URL: $download_url"
	
	# Use the direct download domain
	url="https://dw.uptodown.com$download_url"
	req "$url" "lightroom-beta.apk"
	
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
