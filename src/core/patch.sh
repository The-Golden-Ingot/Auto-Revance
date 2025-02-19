#!/bin/bash

source src/core/utils.sh

# Get patches configuration
get_patches_config() {
    local app=$1
    local excludePatches=""
    local includePatches=""
    local excludeLinesFound=false
    local includeLinesFound=false
    
    # Determine CLI version for patch syntax
    if [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
        local cli_version=${BASH_REMATCH[1]}
        
        # Read exclude patches
        while IFS= read -r line; do
            if [ $cli_version -ge 5 ]; then
                excludePatches+=" -d \"$line\""
            else
                excludePatches+=" -e \"$line\""
            fi
            excludeLinesFound=true
        done < "src/patches/$app/exclude-patches"
        
        # Read include patches
        while IFS= read -r line; do
            if [ $cli_version -ge 5 ]; then
                if [[ "$line" == *"|"* ]]; then
                    local patch_name="${line%%|*}"
                    local options="${line#*|}"
                    includePatches+=" -e \"${patch_name}\" ${options}"
                else
                    includePatches+=" -e \"$line\""
                fi
            else
                includePatches+=" -i \"$line\""
            fi
            includeLinesFound=true
        done < "src/patches/$app/include-patches"
    fi
    
    # Set empty if no patches found
    if [ "$excludeLinesFound" = false ]; then
        excludePatches=""
    fi
    if [ "$includeLinesFound" = false ]; then
        includePatches=""
    fi
    
    echo "$excludePatches $includePatches"
}

# Get compatible version
get_compatible_version() {
    local package=$1
    local lock_version=$2
    local version=""
    
    if [ -z "$version" ] && [ "$lock_version" != "1" ]; then
        if [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
            local cli_version=${BASH_REMATCH[1]}
            if [ $cli_version -ge 5 ]; then
                version=$(java -jar *cli*.jar list-patches --with-packages --with-versions *.rvp | 
                         awk -v pkg="$package" '
                         BEGIN { found = 0 }
                         /^Index:/ { found = 0 }
                         /Package name: / { if ($3 == pkg) { found = 1 } }
                         /Compatible versions:/ {
                             if (found) {
                                 getline
                                 latest_version = $1
                                 while (getline && $1 ~ /^[0-9]+\./) {
                                     latest_version = $1
                                 }
                                 print latest_version
                                 exit
                             }
                         }')
            else
                version=$(jq -r '[.. | objects | select(.name == "'$package'" and .versions != null) | .versions[]] | reverse | .[0] // ""' *.json | uniq)
            fi
        fi
    fi
    echo "$version"
}

# Patch application
patch_app() {
    local app=$1
    local cli_version=$2
    local patches_config
    
    log_success "Patching $app"
    
    # Get patches configuration
    patches_config=$(get_patches_config "$app")
    
    # Execute patching
    java -jar revanced-cli-${cli_version}.jar \
        patch \
        -b *.rvp \
        --out="./release/${app}-patched.apk" \
        $patches_config \
        "./download/${app}.apk"
    
    if [ $? -eq 0 ]; then
        log_success "Successfully patched $app"
    else
        log_error "Failed to patch $app"
        return 1
    fi
}

# Architecture specific patching
patch_arch() {
    local app=$1
    local arch=$2
    local cli_version=$3
    
    log_success "Patching $app for $arch"
    
    # Add architecture specific options if needed
    local arch_opts=""
    case "$arch" in
        "arm64-v8a") arch_opts="--arch arm64-v8a" ;;
        "armeabi-v7a") arch_opts="--arch armeabi-v7a" ;;
        "x86") arch_opts="--arch x86" ;;
        "x86_64") arch_opts="--arch x86_64" ;;
    esac
    
    patch_app "$app" "$cli_version" "$arch_opts"
} 