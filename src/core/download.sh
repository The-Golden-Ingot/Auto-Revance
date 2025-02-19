#!/bin/bash

source src/core/utils.sh

# HTTP request wrapper
_request() {
    if [ "$2" = "-" ]; then
        wget -nv -O "$2" --header="User-Agent: Mozilla/5.0 (Android 14; Mobile; rv:134.0) Gecko/134.0 Firefox/134.0" --header="Content-Type: application/octet-stream" --header="Accept-Language: en-US,en;q=0.9" --header="Connection: keep-alive" --header="Upgrade-Insecure-Requests: 1" --header="Cache-Control: max-age=0" --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" --keep-session-cookies --timeout=30 "$1" || rm -f "$2"
    else
        wget -nv -O "./download/$2" --header="User-Agent: Mozilla/5.0 (Android 14; Mobile; rv:134.0) Gecko/134.0 Firefox/134.0" --header="Content-Type: application/octet-stream" --header="Accept-Language: en-US,en;q=0.9" --header="Connection: keep-alive" --header="Upgrade-Insecure-Requests: 1" --header="Cache-Control: max-age=0" --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" --keep-session-cookies --timeout=30 "$1" || rm -f "./download/$2"
    fi
}

# GitHub asset download
download_github_asset() {
    local repo=$1
    local owner=$2
    local tag=$3
    
    if [ "$tag" = "prerelease" ]; then
        local found=0 assets=0
        releases=$(wget -qO- "https://api.github.com/repos/$owner/$repo/releases")
        while read -r line; do
            if [[ $line == *"\"tag_name\":"* ]]; then
                tag_name=$(echo $line | cut -d '"' -f 4)
                if [ "$tag" == "latest" ] || [ "$tag" == "prerelease" ]; then
                    found=1
                else
                    found=0
                fi
            fi
            if [[ $line == *"\"prerelease\":"* ]]; then
                prerelease=$(echo $line | cut -d ' ' -f 2 | tr -d ',')
                if [ "$tag" == "prerelease" ] && [ "$prerelease" == "true" ] ; then
                    found=1
                elif [ "$tag" == "prerelease" ] && [ "$prerelease" == "false" ]; then
                    found=1
                fi
            fi
            if [[ $line == *"\"assets\":"* ]]; then
                if [ $found -eq 1 ]; then
                    assets=1
                fi
            fi
            if [[ $line == *"\"browser_download_url\":"* ]]; then
                if [ $assets -eq 1 ]; then
                    url=$(echo $line | cut -d '"' -f 4)
                    if [[ $url != *.asc ]]; then
                        name=$(basename "$url")
                        wget -q -O "$name" "$url"
                        log_success "Downloading $name from $owner"
                    fi
                fi
            fi
            if [[ $line == *"],"* ]]; then
                if [ $assets -eq 1 ]; then
                    assets=0
                    break
                fi
            fi
        done <<< "$releases"
    else
        tags=$( [ "$tag" == "latest" ] && echo "latest" || echo "tags/$tag" )
        wget -qO- "https://api.github.com/repos/$owner/$repo/releases/$tags" \
        | jq -r '.assets[] | "\(.browser_download_url) \(.name)"' \
        | while read -r url name; do
            if [[ $url != *.asc ]]; then
                log_success "Downloading $name from $owner"
                wget -q -O "$name" "$url"
            fi
        done
    fi
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

# Download APK with retries
download_apk() {
    local package=$1
    local app_name=$2
    local version=$3
    local arch=$4
    local type=${5:-"APK"}
    local extra_params=$6
    
    if [[ -z $arch ]]; then
        url_regexp='APK<\/span>'
    elif [[ $type == "Bundle" ]] || [[ $type == "Bundle_extract" ]]; then
        url_regexp='BUNDLE<\/span>'
    else
        case $arch in
            arm64-v8a) url_regexp='arm64-v8a'"[^@]*$extra_params"'</div>[^@]*@\([^"]*\)' ;;
            armeabi-v7a) url_regexp='armeabi-v7a'"[^@]*$extra_params"'</div>[^@]*@\([^"]*\)' ;;
            x86) url_regexp='x86'"[^@]*$extra_params"'</div>[^@]*@\([^"]*\)' ;;
            x86_64) url_regexp='x86_64'"[^@]*$extra_params"'</div>[^@]*@\([^"]*\)' ;;
            *) url_regexp='$arch'"[^@]*$extra_params"'</div>[^@]*@\([^"]*\)' ;;
        esac 
    fi
    
    version=$(parse_version "$version")
    log_success "Downloading $app_name version: $version $arch"
    
    local url="https://www.apkmirror.com/apk/$package-$version-release/"
    local output="./download/$app_name.apk"
    
    if [[ "$type" == "Bundle" ]] || [[ "$type" == "Bundle_extract" ]]; then
        output="./download/$app_name.apkm"
    fi
    
    # Try up to 10 times with different versions if needed
    local attempt=0
    while [ $attempt -lt 10 ]; do
        if [[ -z $version ]] || [ $attempt -ne 0 ]; then
            version=$(_request "https://www.apkmirror.com/uploads/?appcategory=$app_name" - | \
                $pup 'div.widget_appmanager_recentpostswidget h5 a.fontBlack text{}' | \
                grep -Evi 'alpha|beta' | \
                grep -oPi '\b\d+(\.\d+)+(?:\-\w+)?(?:\.\d+)?(?:\.\w+)?\b' | \
                sed -n "$((attempt + 1))p")
            version=$(parse_version "$version")
            log_success "Trying version: $version"
        fi
        
        _download_apk "$url" "$url_regexp" "$(basename "$output")" "$type"
        
        if [[ -f "./download/$(basename "$output")" ]]; then
            log_success "Successfully downloaded $app_name"
            break
        else
            ((attempt++))
            log_error "Failed to download $app_name, trying another version"
            unset version
        fi
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