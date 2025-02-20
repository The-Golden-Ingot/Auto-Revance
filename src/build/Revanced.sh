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
	
	# Generate arguments to remove DPIs only (no arch removal needed)
	rip_dpi="--rip-dpi mdpi --rip-dpi hdpi --rip-dpi xhdpi --rip-dpi xxxhdpi --rip-dpi sw600dp --rip-dpi sw672dp --rip-dpi sw720dp --rip-dpi television --rip-dpi watch --rip-dpi car"
	
	# Process arm64v8 APK with DPI stripping
	split_arch "google-photos" "revanced" "$rip_dpi"
}

patch_soundcloud() {
	revanced_dl
	# Patch SoundCloud (Arm64-v8a only):
	get_patches_key "soundcloud"
	get_apk "com.soundcloud.android" "soundcloud" "soundcloud-soundcloud" "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "Bundle_extract"
	
	# First merge the split APK
	split_editor "soundcloud" "soundcloud-merged" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"
	
	# Generate arguments to remove DPIs for the merged APK
	rip_libs=$(gen_rip_libs armeabi-v7a x86 x86_64)
	rip_dpi="--rip-dpi mdpi --rip-dpi hdpi --rip-dpi xhdpi --rip-dpi xxxhdpi --rip-dpi tvdpi \
			 --rip-dpi sw600dp --rip-dpi sw720dp --rip-dpi sw800dp --rip-dpi television \
			 --rip-dpi watch --rip-dpi large --rip-dpi xlarge --rip-dpi small \
			 --rip-dpi h320dp --rip-dpi h360dp --rip-dpi h480dp --rip-dpi h500dp --rip-dpi h550dp --rip-dpi h720dp \
			 --rip-dpi w320dp --rip-dpi w360dp --rip-dpi w400dp --rip-dpi w600dp"
	
	# Now strip DPIs and libs from the merged APK
	split_arch "soundcloud-merged" "revanced" "$rip_libs $rip_dpi"
	
	# Rename the final output file
	mv ./release/soundcloud-merged-arm64-v8a-revanced.apk ./release/soundcloud-revanced.apk
}

case "$1" in
    "googlephotos")
        patch_googlephotos
        ;;
    "soundcloud")
        patch_soundcloud
        ;;
esac
