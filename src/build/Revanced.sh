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
    revanced_dl
    # Patch SoundCloud (Arm64-v8a only):
    get_patches_key "soundcloud"
    
    # Fixed URL format and version handling for SoundCloud
    local url="https://www.apkmirror.com/apk/soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs"
    version=$(curl -s "$url" | $PUP 'div.widget_appmanager_recentpostswidget h5 a.fontBlack text{}' | head -n1 | grep -oP '\d+\.\d+\.\d+')
    
    if [[ -z "$version" ]]; then
        log_error "Failed to detect SoundCloud version"
        exit 1
    fi
    
    download_apk "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "soundcloud" "$version" "" "Bundle_extract"
    
    if [[ ! -f "./download/soundcloud.apkm" ]]; then
        log_error "Failed to download SoundCloud"
        exit 1
    fi
    
    # Extract and process bundle
    log_success "Processing SoundCloud bundle"
    unzip -q "./download/soundcloud.apkm" -d "./download/soundcloud" 
    split_editor "soundcloud" "soundcloud" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64"
    
    # Patch with correct parameters
    if [[ -f "./download/soundcloud.apk" ]]; then
        log_success "Patching SoundCloud using $(ls revanced-cli-*.jar)"
        java -jar revanced-cli-*.jar patch \
            --patch-bundle revanced-patches-*.rvp \
            --out "./release/soundcloud-revanced.apk" \
            --keystore=./src/_ks.keystore \
            --options=./src/options/soundcloud.json \
            $excludePatches$includePatches \
            "./download/soundcloud.apk"
    else
        log_error "SoundCloud APK not found for patching"
        exit 1
    fi
}

# Main function
main() {
    case "$1" in
        "googlephotos") patch_googlephotos "$2" ;;
        "soundcloud") patch_soundcloud ;;
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
