#!/bin/bash
# ReVanced Experiments build 
source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Build Instagram
patch_instagram() {
    local version=${1:-"362.0.0.33.241"}
    
    # Setup directories and tools
    ensure_dirs
    setup_tools
    
    # Download requirements
    download_github_asset "ReVancedExperiments" "Aunali321" "latest"
    download_github_asset "revanced-cli" "revanced" "latest"
    
    # Download and patch Instagram
    download_apk "com.instagram.android" "instagram" "$version" "arm64-v8a" "" "nodpi"
    patch_arch "instagram" "$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K[0-9]+')"
}

# Main function
main() {
    case "$1" in
        "instagram") patch_instagram "$2" ;;
        *)
            echo "Usage: $0 <target> [version]"
            echo "Targets:"
            echo "  instagram    Build Instagram"
            echo ""
            echo "Options:"
            echo "  version   Specific app version (optional)"
            exit 1
            ;;
    esac
}

main "$@"
