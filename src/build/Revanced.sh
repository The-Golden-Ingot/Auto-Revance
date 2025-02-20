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
	get_apk "com.google.android.apps.photos" "google-photos" "photos" "google-inc/photos/google-photos"
	
	# Generate arguments to remove architectures and DPIs
	rip_libs=$(gen_rip_libs armeabi-v7a x86 x86_64)
	rip_dpi="--rip-dpi ldpi --rip-dpi mdpi --rip-dpi hdpi --rip-dpi xhdpi --rip-dpi xxxhdpi --rip-dpi tvdpi"
	
	# Only generate arm64-v8a version with xxhdpi resources
	split_arch "google-photos" "revanced" "$rip_libs $rip_dpi"
}

patch_soundcloud() {
	revanced_dl
	# Patch SoundCloud (Arm64-v8a only):
	get_patches_key "soundcloud"
	get_apk "com.soundcloud.android" "soundcloud" "soundcloud-soundcloud" "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "Bundle_extract"
	
	# Only generate arm64-v8a version and keep xxhdpi (closest to 441 DPI)
	split_editor "soundcloud" "soundcloud" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxxhdpi split_config.tvdpi"
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
