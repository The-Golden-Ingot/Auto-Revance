#!/bin/bash

source src/core/utils.sh

# HTTP request wrapper
_request() {
    local url=$1
    local output=$2
    local headers=(
        "User-Agent: Mozilla/5.0 (Android 14; Mobile; rv:134.0) Gecko/134.0 Firefox/134.0"
        "Content-Type: application/octet-stream"
        "Accept-Language: en-US,en;q=0.9"
        "Connection: keep-alive"
        "Upgrade-Insecure-Requests: 1"
        "Cache-Control: max-age=0"
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
    )
    
    local header_args=""
    for header in "${headers[@]}"; do
        header_args+=" --header=\"$header\""
    done
    
    if [ "$output" = "-" ]; then
        wget -nv -O "$output" $header_args --keep-session-cookies --timeout=30 "$url" || rm -f "$output"
    else
        wget -nv -O "./download/$output" $header_args --keep-session-cookies --timeout=30 "$url" || rm -f "./download/$output"
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

# APKMirror download
download_apk() {
    local package=$1
    local app_name=$2
    local version=$3
    local arch=$4
    local type=${5:-"APK"}
    local extra_params=$6
    
    version=$(parse_version "$version")
    log_success "Downloading $app_name version: $version $arch"
    
    local url="https://www.apkmirror.com/apk/$package-$version-release/"
    local output="./download/$app_name.apk"
    
    if [[ "$type" == "Bundle" ]] || [[ "$type" == "Bundle_extract" ]]; then
        output="./download/$app_name.apkm"
    fi
    
    _fetch_and_process_apk "$url" "$output" "$arch" "$type" "$extra_params"
}

_fetch_and_process_apk() {
    local url=$1
    local output=$2
    local arch=$3
    local type=$4
    local extra_params=$5
    
    # Construct regex based on architecture and type
    local url_regexp
    if [[ -z $arch ]]; then
        url_regexp='APK<\/span>'
    elif [[ "$type" == "Bundle" ]] || [[ "$type" == "Bundle_extract" ]]; then
        url_regexp='BUNDLE<\/span>'
    else
        url_regexp="${arch}[^@]*${extra_params}</div>[^@]*@\([^\"]*\)"
    fi
    
    # Download APK
    url="https://www.apkmirror.com$(_request "$url" - | tr '\n' ' ' | sed -n "s/.*<a[^>]*href=\"\([^\"]*\)\".*${url_regexp}.*/\1/p")"
    url="https://www.apkmirror.com$(_request "$url" - | grep -oP 'class="[^"]*downloadButton[^"]*".*?href="\K[^"]+')"
    url="https://www.apkmirror.com$(_request "$url" - | grep -oP 'id="download-link".*?href="\K[^"]+')"
    
    _request "$url" "$(basename "$output")"
    
    # Process bundle if needed
    if [[ "$type" == "Bundle" ]]; then
        log_success "Merging splits APK to standalone APK"
        java -jar "$APKEDITOR" m -i "$output" -o "${output%.apkm}.apk" > /dev/null 2>&1
    elif [[ "$type" == "Bundle_extract" ]]; then
        unzip "$output" -d "${output%.apkm}" > /dev/null 2>&1
    fi
} 