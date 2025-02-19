#!/bin/bash

source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Download ReVanced requirements
revanced_dl() {
    download_github_asset "revanced-patches" "revanced" "prerelease"
    download_github_asset "revanced-cli" "revanced" "latest"
}

# Build Google Photos
patch_googlephotos() {
    local version=${1:-""}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    revanced_dl
    
    # Get compatible version if not specified
    if [ -z "$version" ]; then
        version=$(get_compatible_version "com.google.android.apps.photos" "0")
    fi
    
    # Download and patch Google Photos
    download_apk "com.google.android.apps.photos" "google-photos" "$version" "arm64-v8a" "" "nodpi"
    patch_arch "google-photos" "$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K[0-9]+')"
}

# Build SoundCloud
patch_soundcloud() {
    local version=${1:-""}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    revanced_dl
    
    # Get compatible version if not specified
    if [ -z "$version" ]; then
        version=$(get_compatible_version "com.soundcloud.android" "0")
    fi
    
    # Download and patch SoundCloud
    download_apk "com.soundcloud.android" "soundcloud" "$version" "" "Bundle_extract" "soundcloud-soundcloud/soundcloud-play-music-songs"
    
    # Process bundle
    log_success "Processing SoundCloud bundle"
    split_editor "soundcloud" "soundcloud" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"
    
    # Patch
    patch_arch "soundcloud" "$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K[0-9]+')"
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
