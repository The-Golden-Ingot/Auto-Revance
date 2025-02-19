#!/bin/bash

source src/core/utils.sh

# Check if we need to build based on version changes
check_version_changes() {
    local should_build=false
    
    # Get latest versions
    local youtube_version=$(get_compatible_version "com.google.android.youtube" "0")
    local music_version=$(get_compatible_version "com.google.android.apps.youtube.music" "0")
    
    # Get current versions from release
    local current_youtube_version=""
    local current_music_version=""
    
    if [ -f "release/versions.txt" ]; then
        current_youtube_version=$(grep "youtube=" "release/versions.txt" | cut -d'=' -f2)
        current_music_version=$(grep "youtube-music=" "release/versions.txt" | cut -d'=' -f2)
    fi
    
    # Compare versions
    if [ "$youtube_version" != "$current_youtube_version" ] || \
       [ "$music_version" != "$current_music_version" ] || \
       [ ! -f "release/youtube-patched.apk" ] || \
       [ ! -f "release/youtube-music-patched.apk" ]; then
        should_build=true
        
        # Update versions file
        mkdir -p release
        echo "youtube=$youtube_version" > "release/versions.txt"
        echo "youtube-music=$music_version" >> "release/versions.txt"
    fi
    
    # Set output for GitHub Actions
    if [ -n "$GITHUB_OUTPUT" ]; then
        echo "should_build=$should_build" >> "$GITHUB_OUTPUT"
    else
        echo "$should_build"
    fi
}

check_version_changes 