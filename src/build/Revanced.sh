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
    local release_type=${2:-"latest"}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    log_success "Downloading revanced patches for SoundCloud"
    download_github_asset "revanced-patches" "revanced" "latest"
    log_success "Downloading revanced-cli for SoundCloud"
    download_github_asset "revanced-cli" "revanced" "latest"
    
    # Download and patch SoundCloud
    log_success "Downloading SoundCloud APK"
    download_apk "com.soundcloud.android" "soundcloud" "$version" "arm64-v8a" "" "nodpi"
    
    # Process splits
    log_success "Processing SoundCloud bundle"
    split_editor "soundcloud" "soundcloud" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxhdpi split_config.tvdpi"
    
    # Patch
    local cli_version=$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K.+(?=\.jar)')
    if [ -z "$cli_version" ]; then
        log_error "Failed to extract revanced-cli version."
        return 1
    fi
    log_success "Patching SoundCloud using revanced-cli-$cli_version.jar"
    java -jar "revanced-cli-${cli_version}.jar" \
         patch \
         -b *.rvp \
         --out="./release/soundcloud.apk" \
         --keystore=./src/_ks.keystore \
         --purge=true \
         --force \
         "./download/soundcloud.apk"
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
