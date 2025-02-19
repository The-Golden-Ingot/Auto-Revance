#!/bin/bash

source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Download ReVanced requirements
revanced_dl() {
    download_github_asset "revanced-patches" "revanced" "prerelease"
    download_github_asset "revanced-cli" "revanced" "latest"
    
    # Ensure we have the CLI jar
    if ! ls revanced-cli-*.jar >/dev/null 2>&1; then
        log_error "Failed to download ReVanced CLI"
        return 1
    fi
}

# Build Google Photos
patch_googlephotos() {
    local version=${1:-""}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    revanced_dl || return 1
    
    # Get compatible version if not specified
    if [ -z "$version" ]; then
        version=$(get_compatible_version "com.google.android.apps.photos" "0")
    fi
    
    # Download and patch Google Photos
    download_apk "google-android-apps-photos" "google-photos" "$version" "arm64-v8a" "" "nodpi" || return 1
    
    # Get CLI version
    local cli_jar=$(ls revanced-cli-*.jar)
    if [ -z "$cli_jar" ]; then
        log_error "ReVanced CLI jar not found"
        return 1
    fi
    
    local cli_version=$(echo "$cli_jar" | grep -oP 'revanced-cli-\K[0-9]+')
    patch_arch "google-photos" "$cli_version"
}

# Build SoundCloud
patch_soundcloud() {
    local version=${1:-""}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    revanced_dl || return 1
    
    # Get compatible version if not specified
    if [ -z "$version" ]; then
        version=$(get_compatible_version "com.soundcloud.android" "0")
    fi
    
    # Download and patch SoundCloud
    download_apk "soundcloud-android" "soundcloud" "$version" "" "Bundle_extract" "soundcloud-soundcloud/soundcloud-play-music-songs" || return 1
    
    # Get CLI version
    local cli_jar=$(ls revanced-cli-*.jar)
    if [ -z "$cli_jar" ]; then
        log_error "ReVanced CLI jar not found"
        return 1
    fi
    
    local cli_version=$(echo "$cli_jar" | grep -oP 'revanced-cli-\K[0-9]+')
    patch_arch "soundcloud" "$cli_version"
}

# Main function
main() {
    case "$1" in
        "googlephotos") patch_googlephotos "$2" ;;
        "soundcloud") patch_soundcloud "$2" ;;
        *)
            echo "Usage: $0 <target> [version]"
            echo "Targets:"
            echo "  googlephotos    Build Google Photos"
            echo "  soundcloud      Build SoundCloud"
            echo ""
            echo "Options:"
            echo "  version   Specific app version (optional)"
            exit 1
            ;;
    esac
}

main "$@"
