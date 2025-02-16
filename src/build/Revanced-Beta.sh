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
	# Patch Google photos (Arm64-v8a only):
	get_patches_key "gg-photos"
	get_apk "com.google.android.apps.photos" "gg-photos-arm64-v8a-beta" "photos" "google-inc/photos/google-photos" "arm64-v8a" "nodpi"
	patch "gg-photos-arm64-v8a-beta" "revanced"
}

patch_lightroom() {
	revanced_dl
	# Patch Lightroom:
	get_patches_key "lightroom"
	
	# Set a common browser user agent
	USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
	
	# First step: Get the version page URL
	html_content=$(curl -s -A "$USER_AGENT" "https://adobe-lightroom-mobile.en.uptodown.com/android/versions")
	
	# Extract the first XAPK version URL from the HTML content
	version_url=$(echo "$html_content" | perl -0777 -ne 'print $1 if /<div[^>]*data-url="([^"]+)"[^>]*>(?:(?!<div).)*?<span class="type xapk"/s')
	
	if [ -z "$version_url" ]; then
	  echo "No version URL found. Check debug.html for the fetched HTML content."
	  echo "$html_content" > debug.html
	  exit 1
	fi
	
	# Add -x suffix to version_url
	version_url="${version_url}-x"
	
	echo "Version page URL: $version_url"
	
	# Second step: Get the download button data-url
	detail_page=$(curl -s -A "$USER_AGENT" "$version_url")
	
	# Extract the data-url from the download button using a more precise pattern
	download_token=$(echo "$detail_page" | perl -0777 -ne 'print $1 if /id="detail-download-button"[^>]+data-url="([^"]+)"/s')
	
	if [ -z "$download_token" ]; then
	  echo "No download token found."
	  exit 1
	fi
	
	# Construct the final download URL
	final_download_url="https://dw.uptodown.com/dwn/$download_token"
	
	echo "Final download URL: $final_download_url"
	
	# Download the XAPK with the final download URL
	req "$final_download_url" "lightroom-beta.xapk"
	
	# Extract and process the XAPK bundle
	rm -rf "./download/lightroom-beta"
	mkdir -p "./download/lightroom-beta"
	unzip -o "./download/lightroom-beta.xapk" -d "./download/lightroom-beta" > /dev/null 2>&1
	
	# Move base.apk to correct location for processing
	if [ -f "./download/lightroom-beta/base.apk" ]; then
		mv "./download/lightroom-beta/base.apk" "./download/lightroom-beta.apk"
	else
		echo "base.apk not found in XAPK bundle"
		exit 1
	fi
	
	# Handle the bundle and create arm64-v8a version
	split_editor "lightroom-beta" "lightroom-arm64-v8a-beta" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"
	
	# Copy the lib directory to the patched APK directory
	if [ -d "./download/lightroom-beta/lib/arm64-v8a" ]; then
		mkdir -p "./release/lib/arm64-v8a"
		cp -r "./download/lightroom-beta/lib/arm64-v8a" "./release/lib/"
	fi
	
	# Patch the arm64-v8a version
	patch "lightroom-arm64-v8a-beta" "revanced"
}

patch_soundcloud() {
	revanced_dl
	# Patch SoundCloud (Arm64-v8a only):
	get_patches_key "soundcloud"
	get_apk "com.soundcloud.android" "soundcloud-beta" "soundcloud-soundcloud" "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "Bundle_extract"
	split_editor "soundcloud-beta" "soundcloud-arm64-v8a-beta" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"
	patch "soundcloud-arm64-v8a-beta" "revanced"
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
