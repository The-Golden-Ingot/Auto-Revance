#!/bin/bash
# Revanced Extended forked by Anddea build
source src/build/utils.sh
# Download requirements
dl_gh "revanced-patches" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"

# Patch YouTube:
get_patches_key "youtube-rve-anddea"
get_apk "com.google.android.youtube" "youtube-beta" "youtube" "google-inc/youtube/youtube"
patch "youtube-beta" "anddea" "inotia"

# Split architecture Youtube:
get_patches_key "youtube-rve-anddea"
for i in {0..3}; do
split_arch "youtube-beta" "anddea" "$(gen_rip_libs ${libs[i]})"
done
