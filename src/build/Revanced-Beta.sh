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
	
	# Create work directories
	WORK_DIR=$(mktemp -d)
	mkdir -p "$WORK_DIR/downloads" "$WORK_DIR/merged" "./download"

	# Cleanup handler
	cleanup() {
		if [ $? -eq 0 ]; then
			echo "🧹 Cleaning temporary files..."
			rm -rf "$WORK_DIR"
		else
			echo "🛑 Error occurred - preserved workdir: $WORK_DIR"
		fi
	}
	trap cleanup EXIT

	# Download and verify XAPK
	echo "📥 Downloading Lightroom XAPK..."
	if ! curl -L -A "$USER_AGENT" -o "$WORK_DIR/downloads/lightroom.xapk" "$final_download_url" || \
		! [ -s "$WORK_DIR/downloads/lightroom.xapk" ] || \
		! unzip -t "$WORK_DIR/downloads/lightroom.xapk" >/dev/null 2>&1; then
		echo "❌ Failed to download valid XAPK"
		exit 1
	fi

	# Extract XAPK
	echo "📦 Extracting XAPK..."
	if ! unzip -o "$WORK_DIR/downloads/lightroom.xapk" -d "$WORK_DIR/downloads" > /dev/null 2>&1; then
		echo "❌ Failed to extract XAPK"
		exit 1
	fi

	# Find and verify base APK
	if [ -f "$WORK_DIR/downloads/base.apk" ]; then
		BASE_APK="$WORK_DIR/downloads/base.apk"
	else
		BASE_APK=$(find "$WORK_DIR/downloads" -maxdepth 1 -type f -name "*.apk" | head -n 1)
		if [ -z "$BASE_APK" ]; then
			echo "❌ No APK found in XAPK"
			exit 1
		fi
	fi

	# Verify APK is valid
	if ! unzip -t "$BASE_APK" >/dev/null 2>&1; then
		echo "❌ Extracted APK is invalid"
		exit 1
	fi

	# Copy base APK to download directory with correct name
	mkdir -p "./download/lightroom-beta"
	cp "$BASE_APK" "./download/lightroom-beta/base.apk"

	# Handle native libraries
	if [ -d "$WORK_DIR/downloads/lib/arm64-v8a" ]; then
		echo "📚 Preserving native libraries..."
		mkdir -p "./download/lightroom-beta/lib/arm64-v8a"
		cp -r "$WORK_DIR/downloads/lib/arm64-v8a/"* "./download/lightroom-beta/lib/arm64-v8a/"
	fi

	# Handle the bundle and create arm64-v8a version
	echo "🔄 Creating arm64-v8a version..."
	split_editor "lightroom-beta" "lightroom-arm64-v8a-beta" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"

	# Copy native libraries to the final APK
	if [ -d "./download/lightroom-beta/lib/arm64-v8a" ]; then
		echo "📚 Copying native libraries to final APK..."
		mkdir -p "./release/lib/arm64-v8a"
		cp -r "./download/lightroom-beta/lib/arm64-v8a/"* "./release/lib/arm64-v8a/"
	fi

	# Patch the arm64-v8a version
	echo "🔨 Patching APK..."
	patch "lightroom-arm64-v8a-beta" "revanced"

	# Cleanup
	rm -rf "./download/lightroom-beta" "./download/lib"
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
