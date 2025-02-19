#!/bin/bash
# Revanced build
source ./src/build/utils.sh
# Download requirements
revanced_dl(){
	dl_gh "revanced-patches" "revanced" "prerelease"
 	dl_gh "revanced-cli" "revanced" "latest"
}

patch_googlephotos() {
	revanced_dl
	# Patch Google photos (Arm64-v8a only):
	get_patches_key "googlephotos"
	get_apk "com.google.android.apps.photos" "google-photos" "photos" "google-inc/photos/google-photos" "arm64-v8a" "nodpi"
	patch "google-photos" "revanced"
}

patch_soundcloud() {
	revanced_dl
	# Patch SoundCloud (Arm64-v8a only):
	get_patches_key "soundcloud"
	get_apk "com.soundcloud.android" "soundcloud" "soundcloud-soundcloud" "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "Bundle_extract"
	split_editor "soundcloud" "soundcloud" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"
	patch "soundcloud" "revanced"
}

case "$1" in
    "googlephotos")
        patch_googlephotos
        ;;
    "soundcloud")
        patch_soundcloud
        ;;
esac
