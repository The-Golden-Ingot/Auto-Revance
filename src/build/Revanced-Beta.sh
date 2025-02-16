#!/bin/bash
# Revanced build
source ./src/build/utils.sh
# Download requirements
revanced_dl(){
	set -e  # Exit immediately on error
	dl_gh "revanced-patches" "revanced" "prerelease"
 	dl_gh "revanced-cli" "revanced" "latest"
	set +e
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
	
	# Get versions page
	versions_page="https://adobe-lightroom-mobile.en.uptodown.com/android/versions"
	green_log "[+] Fetching versions page"
	html_content=$(curl -sL -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36" "$versions_page")
	
	# Extract latest version URL
	data_url=$(echo "$html_content" | $pup 'div#versions-items-list div[data-url]:first-of-type attr{data-url}')
	
	if [ -z "$data_url" ]; then
		red_log "[-] Failed to extract data-url from versions page"
		exit 1
	fi

	# Modify URL with -x suffix
	modified_url="${data_url}-x"
	green_log "[DEBUG] Modified URL: $modified_url"
	
	# Visit modified URL first
	green_log "[+] Visiting modified URL"
	req "$modified_url" - > /dev/null

	# Get final download URL from download button
	green_log "[+] Resolving download URL"
	download_path=$(req "$modified_url" - | $pup -p --charset utf-8 'button#detail-download-button attr{data-url}')
	final_url="https://dw.uptodown.com/dwn/$download_path"
	
	# Extract filename from the download path
	xapk_name=$(basename "$download_path")
	green_log "[DEBUG] XAPK filename: $xapk_name"
	
	# Download using proper Uptodown flow
	green_log "[+] Downloading Lightroom XAPK"
	req "$final_url" "./download/$xapk_name"
	
	if [ ! -f "./download/$xapk_name" ]; then
		red_log "[-] Failed to download Lightroom XAPK"
		exit 1
	fi

	# Process XAPK bundle
	green_log "[+] Processing XAPK bundle"
	unzip "./download/$xapk_name" -d "./download/lightroom-beta" > /dev/null 2>&1
	find "./download/lightroom-beta" -maxdepth 1 -name "*.apk" -exec mv {} "./download/lightroom-beta.apk" \;
	
	if [ ! -f "./download/lightroom-beta.apk" ]; then
		red_log "[-] Failed to extract APK from bundle"
		exit 1
	fi
	
	rm -rf "./download/$xapk_name" "./download/lightroom-beta"
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