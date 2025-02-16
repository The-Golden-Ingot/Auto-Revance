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
	
	# Improved version name extraction
	version_name=$(echo "$html_content" | $pup 'div#versions-items-list div.version:first-of-type text{}' | xargs | tr -cd '[:alnum:].-')
	[ -z "$version_name" ] && { red_log "[-] Failed to extract version name"; exit 1; }

	data_url=$(echo "$html_content" | $pup 'div#versions-items-list div[data-url]:first-of-type attr{data-url}')
	[ -z "$data_url" ] && { red_log "[-] Failed to extract data-url"; exit 1; }

	modified_url="${data_url}-x"
	green_log "[DEBUG] Modified URL: $modified_url"
	
	# Visit modified URL with proper headers
	green_log "[+] Visiting modified URL"
	req "$modified_url" - > /dev/null
	sleep 5

	# Get download URL with error handling
	green_log "[+] Resolving download URL"
	download_page=$(req "$modified_url" -)
	download_path=$(echo "$download_page" | $pup -p --charset utf-8 'button#detail-download-button attr{data-url}')
	[ -z "$download_path" ] && { red_log "[-] Failed to get download path"; exit 1; }
	final_url="https://dw.uptodown.com/dwn/$download_path"
	
	# Download with validation
	xapk_name="adobe-lightroom-${version_name}.xapk"
	green_log "[+] Downloading $xapk_name"
	wget -q --show-progress --content-disposition \
		-O "./download/$xapk_name" "$final_url" || { red_log "[-] Download failed"; exit 1; }

	# Improved XAPK processing
	green_log "[+] Extracting XAPK"
	unzip -o "./download/$xapk_name" -d "./download/lightroom-beta" > /dev/null 2>&1 || { red_log "[-] Failed to unzip XAPK"; exit 1; }
	
	# Find main APK using package name pattern
	main_apk=$(find "./download/lightroom-beta" -name "com.adobe.lrmobile*.apk" -print -quit)
	[ -z "$main_apk" ] && { red_log "[-] No main APK found in bundle"; exit 1; }
	mv "$main_apk" "./download/lightroom-beta.apk"

	# Verify APK structure
	if ! aapt dump badging "./download/lightroom-beta.apk" > /dev/null 2>&1; then
		red_log "[-] Invalid APK structure detected"
		red_log "[DEBUG] APK info:"
		file "./download/lightroom-beta.apk"
		exit 1
	fi

	# Cleanup and patch
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