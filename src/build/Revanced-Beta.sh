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
	
	# Visit versions page
	versions_page="https://adobe-lightroom-mobile.en.uptodown.com/android/versions"
	
	# Extract data-url from first version item
	data_url=$(curl -sL "$versions_page" | pup 'div#versions-items-list div.version-item:first-of-type attr{data-url}')
	
	if [ -z "$data_url" ]; then
		red_log "[-] Failed to extract data-url from versions page"
		exit 1
	fi
	
	# Modify URL with -x suffix
	modified_url="${data_url}-x"
	green_log "[DEBUG] Modified URL: $modified_url"
	
	# First visit the modified URL
	green_log "[+] Visiting modified URL"
	req "$modified_url" -
	
	# Wait for page "load" (simulated delay)
	sleep 5
	
	# Download using modified URL with required headers
	green_log "[+] Downloading Lightroom from modified URL"
	wget -q --show-progress --content-disposition \
		--header="Referer: $modified_url" \
		"$modified_url" -O "./download/lightroom-beta.apk"
	
	if [ ! -f "./download/lightroom-beta.apk" ]; then
		red_log "[-] Failed to download Lightroom APK"
		exit 1
	fi
	
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