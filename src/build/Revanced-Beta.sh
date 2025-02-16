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
	
	# Step 1: Visit initial download page
	initial_page=$(req "https://adobe-lightroom-mobile.en.uptodown.com/android/download" -)
	
	if [ -z "$initial_page" ]; then
		echo "Failed to load initial page"
		exit 1
	fi
	
	# Try multiple extraction methods for variants URL
	variants_url=$(
	    # Method 1: Try pup CSS selector
	    echo "$initial_page" | $pup '#variants-button attr{onclick}' | sed -n "s/.*window\.location\s*=\s*['\"]\([^'\"]*\)['\"].*/\1/p" ||
	    # Fallback Method 2: Use grep for pattern matching
	    echo "$initial_page" | grep -Eo "window\.location\s*=\s*['\"][^'\"]+['\"]" | head -1 | sed "s/window\.location\s*=\s*['\"]\([^'\"]*\)['\"]/\1/"
	)
	
	# Add URL validation with multiple fallbacks
	if [[ ! "$variants_url" =~ ^https:// ]]; then
	    # Handle different URL patterns
	    if [[ "$variants_url" =~ ^/ ]]; then
	        variants_url="https://adobe-lightroom-mobile.en.uptodown.com$variants_url"
	    else
	        variants_url="https://adobe-lightroom-mobile.en.uptodown.com/android/variant/$variants_url"
	    fi
	fi
	
	# Add verbose logging for debugging
	green_log "[DEBUG] Variants URL: $variants_url"
	
	# Verify URL format before proceeding
	if [[ ! "$variants_url" =~ ^https://.*uptodown.com ]]; then
	    red_log "[-] Invalid variants URL format: $variants_url"
	    exit 1
	fi
	
	variants_page=$(req "$variants_url" -)
	
	# Step 3: Get version-specific URL from variants
	version_url=$(
	    echo "$variants_page" | $pup '.variant .v-icon attr{onclick}' | 
	    sed -n "s/.*['\"]\(https[^'\"]*\)['\"].*/\1/p" |
	    head -1
	)
	
	if [ -z "$version_url" ]; then
	    red_log "[-] Variants page content for debugging:"
	    echo "$variants_page" | head -n 40
	    red_log "[-] Failed to extract version URL from variants page"
	    exit 1
	fi
	
	# Step 4: Visit version-specific page
	version_page=$(req "$version_url" -)
	
	# Step 5: Wait required time before getting download button
	sleep 10  # Increased from 5 to 10 seconds
	
	# Step 6: Get final download URL from the button
	download_url=$(echo "$version_page" | $pup 'button#detail-download-button attr{data-url}' | tr -d '[:space:]')
	
	if [ -z "$download_url" ]; then
		echo "Failed to extract download URL"
		exit 1
	fi
	
	# Step 7: Download the XAPK
	req "https://dw.uptodown.com/dwn/$download_url" "lightroom-beta.xapk"
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