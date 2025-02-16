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
	
	# Extract second version URL using the data-url attribute from the versions-items-list;
	# Note: we use :nth-child(2) since the first div is the first version.
	version_url=$(echo "$versions_page" | $pup '.versions .content div:nth-child(2) attr{data-url}')
	
	if [ -z "$version_url" ]; then
		echo "Failed to extract version URL"
		exit 1
	fi
	
	# Download the specific version's detailed page and extract the final download URL from the button
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
