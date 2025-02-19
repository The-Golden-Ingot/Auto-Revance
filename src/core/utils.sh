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
    
    # Setup APKEditor
    wget -q -O ./APKEditor.jar "https://github.com/REAndroid/APKEditor/releases/download/V1.4.1/APKEditor-1.4.1.jar"
}

# Export tool paths
export PUP="./pup"
export APKEDITOR="./APKEditor.jar" 