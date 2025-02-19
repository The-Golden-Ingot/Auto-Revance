#!/bin/bash

source src/core/utils.sh
source src/core/patch.sh

# Check if we need to build based on version changes
check_version_changes() {
    local should_build=false
    
    # Get latest versions
    local youtube_version=$(get_compatible_version "com.google.android.youtube" "0")
    local twitter_version=$(get_compatible_version "com.twitter.android" "0")
    local instagram_version=$(get_compatible_version "com.instagram.android" "0")
    local photos_version=$(get_compatible_version "com.google.android.apps.photos" "0")
    local soundcloud_version=$(get_compatible_version "com.soundcloud.android" "0")
    
    # Get current versions from release
    local current_youtube_version=""
    local current_twitter_version=""
    local current_instagram_version=""
    local current_photos_version=""
    local current_soundcloud_version=""
    
    if [ -f "release/versions.txt" ]; then
        current_youtube_version=$(grep "youtube=" "release/versions.txt" | cut -d'=' -f2)
        current_twitter_version=$(grep "twitter=" "release/versions.txt" | cut -d'=' -f2)
        current_instagram_version=$(grep "instagram=" "release/versions.txt" | cut -d'=' -f2)
        current_photos_version=$(grep "google-photos=" "release/versions.txt" | cut -d'=' -f2)
        current_soundcloud_version=$(grep "soundcloud=" "release/versions.txt" | cut -d'=' -f2)
    fi
    
    # Compare versions
    if [ "$youtube_version" != "$current_youtube_version" ] || \
       [ "$twitter_version" != "$current_twitter_version" ] || \
       [ "$instagram_version" != "$current_instagram_version" ] || \
       [ "$photos_version" != "$current_photos_version" ] || \
       [ "$soundcloud_version" != "$current_soundcloud_version" ] || \
       [ ! -f "release/youtube-patched.apk" ] || \
       [ ! -f "release/twitter-patched.apk" ] || \
       [ ! -f "release/instagram-patched.apk" ] || \
       [ ! -f "release/google-photos-patched.apk" ] || \
       [ ! -f "release/soundcloud-patched.apk" ]; then
        should_build=true
        
        # Update versions file
        mkdir -p release
        echo "youtube=$youtube_version" > "release/versions.txt"
        echo "twitter=$twitter_version" >> "release/versions.txt"
        echo "instagram=$instagram_version" >> "release/versions.txt"
        echo "google-photos=$photos_version" >> "release/versions.txt"
        echo "soundcloud=$soundcloud_version" >> "release/versions.txt"
    fi
    
    # Set output for GitHub Actions
    if [ -n "$GITHUB_OUTPUT" ]; then
        echo "should_build=$should_build" >> "$GITHUB_OUTPUT"
    else
        echo "$should_build"
    fi
}

check_version_changes 