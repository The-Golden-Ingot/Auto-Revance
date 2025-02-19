#!/bin/bash

# Logging utilities
log() {
    local color=$1
    local message=$2
    echo -e "\e[${color}m${message}\e[0m"
}

log_success() {
    log "32" "[+] $1"
}

log_error() {
    log "31" "[-] $1"
}

# Version handling
parse_version() {
    echo "$1" | tr -d ' ' | sed 's/\./-/g'
}

# File operations
ensure_dirs() {
    mkdir -p ./release ./download
}

# Tool setup
setup_tools() {
    # Setup pup
    wget -q -O ./pup.zip "https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_amd64.zip"
    unzip "./pup.zip" -d "./" > /dev/null 2>&1
    chmod +x ./pup
    # Setup APKEditor
    wget -q -O ./APKEditor.jar "https://github.com/REAndroid/APKEditor/releases/download/V1.4.1/APKEditor-1.4.1.jar"
}

# Export tool paths
export PUP="./pup"
export APKEDITOR="./APKEditor.jar"

split_editor() {
    if [[ -z "$3" || -z "$4" ]]; then
        log_success "Merging splits apk to standalone apk"
        java -jar "$APKEDITOR" m -i "./download/$1" -o "./download/$1.apk" > /dev/null 2>&1
        return 0
    fi
    IFS=' ' read -r -a include_files <<< "$4"
    mkdir -p "./download/$2"
    for file in "./download/$1"/*.apk; do
        filename=$(basename "$file")
        basename_no_ext="${filename%.apk}"
        if [[ "$filename" == "base.apk" ]]; then
            cp -f "$file" "./download/$2/" > /dev/null 2>&1
            continue
        fi
        if [[ "$3" == "include" ]]; then
            if [[ " ${include_files[*]} " =~ " ${basename_no_ext} " ]]; then
                cp -f "$file" "./download/$2/" > /dev/null 2>&1
            fi
        elif [[ "$3" == "exclude" ]]; then
            if [[ ! " ${include_files[*]} " =~ " ${basename_no_ext} " ]]; then
                cp -f "$file" "./download/$2/" > /dev/null 2>&1
            fi
        fi
    done
    log_success "Merging splits apk to standalone apk"
    java -jar "$APKEDITOR" m -i "./download/$2" -o "./download/$2.apk" > /dev/null 2>&1
} 