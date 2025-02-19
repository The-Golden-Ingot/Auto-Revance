#!/bin/bash

source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Download ReVanced requirements
revanced_dl() {
    download_github_asset "revanced-patches" "revanced" "prerelease"
    download_github_asset "revanced-cli" "revanced" "latest"
}

# Get patches configuration
get_patches_key() {
    excludePatches=""
    includePatches=""
    excludeLinesFound=false
    includeLinesFound=false
    
    if [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
        num=${BASH_REMATCH[1]}
        if [ $num -ge 5 ]; then
            while IFS= read -r line1; do
                [[ -n "$line1" && "$line1" != \#* ]] && excludePatches+=" -d \"$line1\""
                excludeLinesFound=true
            done < src/patches/$1/exclude-patches
            while IFS= read -r line2; do
                [[ -n "$line2" && "$line2" != \#* ]] && includePatches+=" -e \"$line2\""
                includeLinesFound=true
            done < src/patches/$1/include-patches
        else
            while IFS= read -r line1; do
                [[ -n "$line1" && "$line1" != \#* ]] && excludePatches+=" -e \"$line1\""
                excludeLinesFound=true
            done < src/patches/$1/exclude-patches
            while IFS= read -r line2; do
                [[ -n "$line2" && "$line2" != \#* ]] && includePatches+=" -i \"$line2\""
                includeLinesFound=true
            done < src/patches/$1/include-patches
        fi
    fi
    
    [ "$excludeLinesFound" = false ] && excludePatches=""
    [ "$includeLinesFound" = false ] && includePatches=""
    
    export excludePatches
    export includePatches
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
    # Setup directories
    mkdir -p download release
    
    # Download requirements
    revanced_dl
    
    # Get patches configuration
    get_patches_key "soundcloud"
    
    # Get latest version from APKMirror
    local url="https://www.apkmirror.com/apk/soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs"
    version=$(wget -qO- "$url" | grep -oP 'SoundCloud [0-9.]+' | head -1 | grep -oP '[0-9.]+')
    
    if [[ -z "$version" ]]; then
        log_error "Failed to detect SoundCloud version"
        exit 1
    fi
    
    log_success "Detected SoundCloud version: $version"
    
    # Download APK
    download_apk "soundcloud/soundcloud-soundcloud/soundcloud-play-music-songs" "soundcloud" "$version" "" "Bundle_extract"
    
    if [[ ! -f "./download/soundcloud.apkm" ]]; then
        log_error "Failed to download SoundCloud"
        exit 1
    fi
    
    # Extract and process bundle
    log_success "Processing SoundCloud bundle"
    unzip -q "./download/soundcloud.apkm" -d "./download/soundcloud"
    
    # Move base.apk to correct location
    if [[ -f "./download/soundcloud/base.apk" ]]; then
        mv "./download/soundcloud/base.apk" "./download/soundcloud.apk"
    fi
    
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
