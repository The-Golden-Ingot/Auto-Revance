#!/bin/bash

source src/core/utils.sh

# HTTP request wrapper
_request() {
    local url=$1
    local output=$2
    local headers=(
        'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
        'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8'
        'Accept-Language: en-US,en;q=0.9'
        'Connection: keep-alive'
        'Upgrade-Insecure-Requests: 1'
        'Cache-Control: max-age=0'
        'Referer: https://www.apkmirror.com'
    )
    
    if [ "$output" = "-" ]; then
        wget -nv -O "$output" $(printf -- "--header='%s' " "${headers[@]}") --keep-session-cookies --timeout=30 "$url" || rm -f "$output"
    else
        wget -nv -O "./download/$output" $(printf -- "--header='%s' " "${headers[@]}") --keep-session-cookies --timeout=30 "$url" || rm -f "./download/$output"
    fi
}

# GitHub asset download
download_github_asset() {
    local repo=$1
    local owner=$2
    local tag=$3
    
    if [ "$tag" = "prerelease" ]; then
        _download_github_prerelease "$repo" "$owner"
    else
        _download_github_release "$repo" "$owner" "$tag"
    fi
}

_download_github_prerelease() {
    local repo=$1
    local owner=$2
    local releases=$(wget -qO- "https://api.github.com/repos/$owner/$repo/releases")
    
    while read -r line; do
        if [[ $line == *"\"browser_download_url\":"* ]]; then
            url=$(echo $line | cut -d '"' -f 4)
            if [[ $url != *.asc ]]; then
                name=$(basename "$url")
                wget -q -O "$name" "$url"
                log_success "Downloading $name from $owner"
            fi
        fi
    done <<< "$releases"
}

_download_github_release() {
    local repo=$1
    local owner=$2
    local tag=$3
    local tag_path=$([[ "$tag" == "latest" ]] && echo "latest" || echo "tags/$tag")
    
    wget -qO- "https://api.github.com/repos/$owner/$repo/releases/$tag_path" \
    | jq -r '.assets[] | "\(.browser_download_url) \(.name)"' \
    | while read -r url name; do
        if [[ $url != *.asc ]]; then
            log_success "Downloading $name from $owner"
            wget -q -O "$name" "$url"
        fi
    done
}

# Download APK from APKMirror
_download_apk() {
    local url=$1
    local regexp=$2
    local output=$3
    local type=$4
    
    # Get download URL
    if [[ -z "$type" ]] || [[ $type == "Bundle" ]] || [[ $type == "Bundle_extract" ]]; then
        url="https://www.apkmirror.com$(_request "$url" - | tr '\n' ' ' | sed -n "s/.*<a[^>]*href=\"\([^\"]*\)\".*${regexp}.*/\1/p")"
    else
        url="https://www.apkmirror.com$(_request "$url" - | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
    fi
    
    # Get final download URL
    url="https://www.apkmirror.com$(_request "$url" - | grep -oP 'class="[^"]*downloadButton[^"]*".*?href="\K[^"]+')"
    url="https://www.apkmirror.com$(_request "$url" - | grep -oP 'id="download-link".*?href="\K[^"]+')"
    
    # Download file
    if [[ "$url" == "https://www.apkmirror.com" ]]; then
        return 1
    fi
    _request "$url" "$output"
}

# Get latest version from APKMirror
_get_latest_version() {
    local app_name=$1
    local attempt=$2
    
    # Get version from APKMirror
    version=$(_request "https://www.apkmirror.com/uploads/?appcategory=$app_name" - | \
        pup 'div.widget_appmanager_recentpostswidget h5 a.fontBlack text{}' | \
        grep -Evi 'alpha|beta' | \
        grep -oPi '\b\d+(\.\d+)+(?:\-\w+)?(?:\.\d+)?(?:\.\w+)?\b' | \
        sed -n "$((attempt + 1))p")
    
    echo "$version"
}

# Download APK with retries
download_apk() {
    local package=$1
    local app_name=$2
    local version=$3
    local arch=$4
    local type=${5:-"APK"}
    local extra_params=$6
    
    version=$(parse_version "$version")
    log_success "Downloading $app_name version: $version $arch"
    
    local url="https://www.apkmirror.com/apk/$package/$app_name/$app_name-$version-release/"
    local output="./download/$app_name.apk"
    
    if [[ "$type" == "Bundle" ]] || [[ "$type" == "Bundle_extract" ]]; then
        output="./download/$app_name.apkm"
    fi
    
    # Try up to 10 times with different versions if needed
    local attempt=0
    while [ $attempt -lt 10 ]; do
        if [[ -z $version ]] || [ $attempt -ne 0 ]; then
            version=$(_get_latest_version "$app_name" "$attempt")
            version=$(parse_version "$version")
            log_success "Trying version: $version"
        fi
        
        # Get download page URL
        local download_page=$(_request "$url" - | pup 'a[href*="download"] attr{href}' | head -n1)
        if [ -n "$download_page" ]; then
            download_page="https://www.apkmirror.com$download_page"
            
            # Get final download URL
            local final_url=$(_request "$download_page" - | pup 'a#downloadButton attr{href}' | head -n1)
            if [ -n "$final_url" ]; then
                final_url="https://www.apkmirror.com$final_url"
                _request "$final_url" "$(basename "$output")"
                
                if [[ -f "./download/$(basename "$output")" ]]; then
                    log_success "Successfully downloaded $app_name"
                    break
                fi
            fi
        fi
        
        ((attempt++))
        log_error "Failed to download $app_name, trying another version"
        unset version
    done
    
    if [ $attempt -eq 10 ]; then
        log_error "No more versions to try. Failed download"
        return 1
    fi
    
    # Process bundle if needed
    if [[ "$type" == "Bundle" ]]; then
        log_success "Merging splits APK to standalone APK"
        java -jar "$APKEDITOR" m -i "$output" -o "${output%.apkm}.apk" > /dev/null 2>&1
    elif [[ "$type" == "Bundle_extract" ]]; then
        unzip "$output" -d "${output%.apkm}" > /dev/null 2>&1
    fi
} 