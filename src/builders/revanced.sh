#!/bin/bash

source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Build YouTube
build_youtube() {
    local version=${1:-""}
    local arch=${2:-"arm64-v8a"}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    download_github_asset "revanced-patches" "revanced" "latest"
    download_github_asset "revanced-cli" "revanced" "latest"
    
    # Get compatible version if not specified
    if [ -z "$version" ]; then
        version=$(get_compatible_version "com.google.android.youtube" "0")
    fi
    
    # Download and patch YouTube
    download_apk "com.google.android.youtube" "youtube" "$version" "$arch"
    patch_arch "youtube" "$arch" "$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K[0-9]+')"
}

# Build YouTube Music
build_youtube_music() {
    local version=${1:-""}
    local arch=${2:-"arm64-v8a"}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    download_github_asset "revanced-patches" "revanced" "latest"
    download_github_asset "revanced-cli" "revanced" "latest"
    
    # Get compatible version if not specified
    if [ -z "$version" ]; then
        version=$(get_compatible_version "com.google.android.apps.youtube.music" "0")
    fi
    
    # Download and patch YouTube Music
    download_apk "com.google.android.apps.youtube.music" "youtube-music" "$version" "$arch"
    patch_arch "youtube-music" "$arch" "$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K[0-9]+')"
}

# Main function
main() {
    case "$1" in
        "youtube") build_youtube "$2" "$3" ;;
        "youtube-music") build_youtube_music "$2" "$3" ;;
        *)
            echo "Usage: $0 <target> [version] [arch]"
            echo "Targets:"
            echo "  youtube         Build YouTube"
            echo "  youtube-music   Build YouTube Music"
            echo ""
            echo "Options:"
            echo "  version   Specific app version (optional)"
            echo "  arch      Target architecture (default: arm64-v8a)"
            exit 1
            ;;
    esac
}

main "$@" 