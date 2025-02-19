#!/bin/bash

source src/core/utils.sh
source src/core/download.sh
source src/core/patch.sh

# Build Twitter
patch_twitter() {
	local version=${1:-""}
	local release_type=${2:-"prerelease"}
	
	# Setup directories and tools
	ensure_dirs
	setup_tools
	
	# Download requirements
	download_github_asset "revanced-cli" "revanced" "v4.6.0"
	download_github_asset "piko revanced-integrations" "crimera" "$release_type"
	
	# Download and patch Twitter
	download_apk "com.twitter.android" "twitter" "$version" "" "Bundle_extract" "x-corp/twitter/x-previously-twitter"
	
	# Process bundle
	log_success "Processing Twitter bundle"
	split_editor "twitter" "twitter" "exclude" "split_config.armeabi_v7a split_config.x86 split_config.x86_64 split_config.mdpi split_config.hdpi split_config.xhdpi split_config.xxhdpi split_config.tvdpi"
	
	# Patch
	patch_arch "twitter" "$(ls revanced-cli-*.jar | grep -oP 'revanced-cli-\K[0-9]+')"
}

# Main function
main() {
	case "$1" in
		"prerelease"|"latest")
			patch_twitter "" "$1"
			;;
		*)
			echo "Usage: $0 <release_type>"
			echo "Release Types:"
			echo "  prerelease    Use prerelease version"
			echo "  latest        Use latest stable version"
			exit 1
			;;
	esac
}

main "$@"
