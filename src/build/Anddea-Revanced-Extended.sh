#!/bin/bash
# Revanced Extended forked by Anddea build
source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Build YouTube
patch_youtube() {
    local version=${1:-""}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    download_github_asset "revanced-patches" "anddea" "prerelease"
    download_github_asset "revanced-cli" "inotia00" "latest"
    
    # Download and patch YouTube
    download_apk "com.google.android.youtube" "youtube" "$version" "arm64-v8a" "" "nodpi"
    
    # Patch with inotia settings
    unset CI GITHUB_ACTION GITHUB_ACTIONS GITHUB_ACTOR GITHUB_ENV GITHUB_EVENT_NAME GITHUB_EVENT_PATH GITHUB_HEAD_REF GITHUB_JOB GITHUB_REF GITHUB_REPOSITORY GITHUB_RUN_ID GITHUB_RUN_NUMBER GITHUB_SHA GITHUB_WORKFLOW GITHUB_WORKSPACE RUN_ID RUN_NUMBER
    
    local cli_jar=$(ls revanced-cli-*.jar)
    if [ -z "$cli_jar" ]; then
        log_error "ReVanced CLI jar not found"
        return 1
    fi
    
    local cli_version=$(echo "$cli_jar" | grep -oP 'revanced-cli-\K[0-9]+')
    java -jar "$cli_jar" \
        patch \
        -b *.rvp \
        --out="./release/youtube-anddea.apk" \
        --keystore=./src/_ks.keystore \
        --purge=true \
        --force \
        "./download/youtube.apk"
}

# Main function
main() {
    case "$1" in
        "youtube") patch_youtube "$2" ;;
        *)
            echo "Usage: $0 <target> [version]"
            echo "Targets:"
            echo "  youtube    Build YouTube"
            echo ""
            echo "Options:"
            echo "  version   Specific app version (optional)"
            exit 1
            ;;
    esac
}

main "$@"
