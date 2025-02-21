#!/bin/bash

mkdir ./release ./download

# Install required packages
npm install apkmirror-downloader@latest

#Setup APKEditor for install combine split apks
wget -q -O ./APKEditor.jar https://github.com/REAndroid/APKEditor/releases/download/V1.4.1/APKEditor-1.4.1.jar
APKEditor="./APKEditor.jar"

#################################################

# Colored output logs
green_log() {
    echo -e "\e[32m$1\e[0m"
}
red_log() {
    echo -e "\e[31m$1\e[0m"
}

#################################################

# Download Github assets requirement:
dl_gh() {
	if [ $3 == "prerelease" ]; then
		local repo=$1
		for repo in $1 ; do
			local owner=$2 tag=$3 found=0 assets=0
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
							green_log "[+] Downloading $name from $owner"
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
		done
	else
		for repo in $1 ; do
			tags=$( [ "$3" == "latest" ] && echo "latest" || echo "tags/$3" )
			wget -qO- "https://api.github.com/repos/$2/$repo/releases/$tags" \
			| jq -r '.assets[] | "\(.browser_download_url) \(.name)"' \
			| while read -r url names; do
   				if [[ $url != *.asc ]]; then
					green_log "[+] Downloading $names from $2"
					wget -q -O "$names" $url
     				fi
			done
		done
	fi
}

#################################################

# Get patches list:
get_patches_key() {
	excludePatches=""
	includePatches=""
	excludeLinesFound=false
	includeLinesFound=false
	if [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
		num=${BASH_REMATCH[1]}
		if [ $num -ge 5 ]; then
			while IFS= read -r line1; do
				excludePatches+=" -d \"$line1\""
				excludeLinesFound=true
			done < src/patches/$1/exclude-patches
			while IFS= read -r line2; do
				if [[ "$line2" == *"|"* ]]; then
					patch_name="${line2%%|*}"
					options="${line2#*|}"
					includePatches+=" -e \"${patch_name}\" ${options}"
				else
					includePatches+=" -e \"$line2\""
				fi
				includeLinesFound=true
			done < src/patches/$1/include-patches
		else
			while IFS= read -r line1; do
				excludePatches+=" -e \"$line1\""
				excludeLinesFound=true
			done < src/patches/$1/exclude-patches
			
			while IFS= read -r line2; do
				includePatches+=" -i \"$line2\""
				includeLinesFound=true
			done < src/patches/$1/include-patches
		fi
	fi
	if [ "$excludeLinesFound" = false ]; then
		excludePatches=""
	fi
	if [ "$includeLinesFound" = false ]; then
		includePatches=""
	fi
	export excludePatches
	export includePatches
}

#################################################

# Download apks files using APKMD (APKMirror Downloader)
# Parameters:
#   $1: organization (e.g., google-inc)
#   $2: repository (e.g., youtube)
#   $3: output filename
#   $4: architecture (optional)
#   $5: DPI (optional)
#   $6: type (apk/bundle)
#   $7: version (optional)
#   $8: minimum Android version (optional)
dl_apkmd() {
    local org="$1"
    local repo="$2"
    local output="$3"
    local options=()
    
    [[ ! -z "$4" ]] && options+=(--arch "$4")
    [[ ! -z "$5" ]] && options+=(--dpi "$5")
    [[ ! -z "$6" ]] && options+=(--type "$6")
    [[ ! -z "$7" ]] && options+=(--version "$7")
    [[ ! -z "$8" ]] && options+=(--min-android-version "$8")
    
    green_log "[+] Downloading ${org}/${repo} with options: ${options[*]}"
    
    if npx apkmirror-downloader download \
        --org "$org" \
        --repo "$repo" \
        --outDir "./download" \
        --outFile "$output" \
        "${options[@]}"; then
        green_log "[+] Successfully downloaded ${output}"
        return 0
    else
        red_log "[-] Failed to download ${output}"
        return 1
    fi
}

# Unified APK getter using APKMD
get_apk() {
    local package_name="$1"
    local output_name="$2"
    local app_name="$3"
    local apkmirror_path="$4"
    local apk_type="${5:-apk}"
    local arch="${6:-}"
    local dpi="${7:-}"
    local version="${8:-}"
    local min_android="${9:-}"

    IFS='/' read -ra path_parts <<< "$apkmirror_path"
    local org="${path_parts[0]}"
    local repo="${path_parts[1]}"

    # Validate version format if specified
    if [[ -n "$version" && ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        red_log "[-] Invalid version format: $version"
        return 1
    }

    # Try specified version first
    if [[ -n "$version" ]]; then
        dl_apkmd "$org" "$repo" "$output_name" "$arch" "$dpi" "$apk_type" "$version" "$min_android" && return 0
    fi

    # Fallback to latest version
    local attempt=0
    while [ $attempt -lt 3 ]; do
        dl_apkmd "$org" "$repo" "$output_name" "$arch" "$dpi" "$apk_type" "" "$min_android" && return 0
        ((attempt++))
        sleep 1
    done

    red_log "[-] Failed to download after 3 attempts"
    return 1
}

#################################################

# Patching apps with Revanced CLI:
patch() {
	green_log "[+] Patching $1:"
	if [ -f "./download/$1.apk" ]; then
		local p b m ks a pu opt force
		if [ "$3" = inotia ]; then
			p="patch " b="-p *.rvp" m="" a="" ks="_ks" pu="--purge=true" opt="--legacy-options=./src/options/$2.json" force=" --force"
			echo "Patching with Revanced-cli inotia"
		else
			if [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
				num=${BASH_REMATCH[1]}
				if [ $num -ge 5 ]; then
					p="patch " b="-p *.rvp" m="" a="" ks="ks" pu="--purge=true" opt="" force=" --force"
					echo "Patching with Revanced-cli version 5+"
				elif [ $num -eq 4 ]; then
					p="patch " b="--patch-bundle *patch*.jar" m="--merge *integration*.apk " a="" ks="ks" pu="--purge=true" opt="--options=./src/options/$2.json "
					echo "Patching with Revanced-cli version 4"
				elif [ $num -eq 3 ]; then
					p="patch " b="--patch-bundle *patch*.jar" m="--merge *integration*.apk " a="" ks="_ks" pu="--purge=true" opt="--options=./src/options/$2.json "
					echo "Patching with Revanced-cli version 3"
				elif [ $num -eq 2 ]; then
					p="" b="--bundle *patch*.jar" m="--merge *integration*.apk " a="--apk " ks="_ks" pu="--clean" opt="--options=./src/options/$2.json "
					echo "Patching with Revanced-cli version 2"
				fi
			fi
		fi
		if [ "$3" = inotia ]; then
			unset CI GITHUB_ACTION GITHUB_ACTIONS GITHUB_ACTOR GITHUB_ENV GITHUB_EVENT_NAME GITHUB_EVENT_PATH GITHUB_HEAD_REF GITHUB_JOB GITHUB_REF GITHUB_REPOSITORY GITHUB_RUN_ID GITHUB_RUN_NUMBER GITHUB_SHA GITHUB_WORKFLOW GITHUB_WORKSPACE RUN_ID RUN_NUMBER
		fi
		eval java -jar *cli*.jar $p$b $m$opt --out=./release/$1-$2.apk$excludePatches$includePatches --keystore=./src/$ks.keystore $pu$force $a./download/$1.apk
  		unset version
		unset lock_version
		unset excludePatches
		unset includePatches
	else 
		red_log "[-] Not found $1.apk"
		exit 1
	fi
}

#################################################

split_editor() {
    if [[ -z "$3" || -z "$4" ]]; then
        green_log "[+] Merge splits apk to standalone apk"
        java -jar $APKEditor m -i "./download/$1" -o "./download/$1.apk" > /dev/null 2>&1
        return 0
    fi
    
    green_log "[+] Processing split APK configurations"
    IFS=' ' read -r -a include_files <<< "$4"
    mkdir -p "./download/$2"
    
    # Copy base APK first
    if [[ -f "./download/$1/base.apk" ]]; then
        cp -f "./download/$1/base.apk" "./download/$2/" > /dev/null 2>&1
    else
        red_log "[-] Base APK not found"
        exit 1
    fi
    
    # Process other splits
    for file in "./download/$1"/*.apk; do
        filename=$(basename "$file")
        basename_no_ext="${filename%.apk}"
        
        # Skip base.apk as it's already handled
        if [[ "$filename" == "base.apk" ]]; then
            continue
        fi
        
        if [[ "$3" == "include" ]]; then
            if [[ " ${include_files[*]} " =~ " ${basename_no_ext} " ]]; then
                cp -f "$file" "./download/$2/" > /dev/null 2>&1 || green_log "[!] Skipping non-existent split: $basename_no_ext"
            fi
        elif [[ "$3" == "exclude" ]]; then
            if [[ ! " ${include_files[*]} " =~ " ${basename_no_ext} " ]]; then
                cp -f "$file" "./download/$2/" > /dev/null 2>&1 || green_log "[!] Skipping non-existent split: $basename_no_ext"
            fi
        fi
    done

    green_log "[+] Merge splits apk to standalone apk"
    java -jar $APKEditor m -i ./download/$2 -o ./download/$2.apk > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        red_log "[-] Failed to merge APK splits"
        exit 1
    fi
}

#################################################

# Split architectures using Revanced CLI, created by inotia00
archs=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")
libs=("armeabi-v7a x86_64 x86" "arm64-v8a x86_64 x86" "armeabi-v7a arm64-v8a x86" "armeabi-v7a arm64-v8a x86_64")
gen_rip_libs() {
	for lib in $@; do
		echo -n "--rip-lib "$lib" "
	done
}
i=0  # Add index for arm64-v8a
split_arch() {
    green_log "[+] Splitting $1 to ${archs[i]}:"
    if [ ! -f "./download/$1.apk" ]; then
        red_log "[-] Not found $1.apk"
        exit 1
    fi

    unset CI GITHUB_ACTION GITHUB_ACTIONS GITHUB_ACTOR GITHUB_ENV GITHUB_EVENT_NAME GITHUB_EVENT_PATH GITHUB_HEAD_REF GITHUB_JOB GITHUB_REF GITHUB_REPOSITORY GITHUB_RUN_ID GITHUB_RUN_NUMBER GITHUB_SHA GITHUB_WORKFLOW GITHUB_WORKSPACE RUN_ID RUN_NUMBER
    
    # Extract DPI and lib arguments
    local dpi_args="" lib_args=""
    for arg in $3; do
        if [[ "$arg" == "--rip-dpi"* ]]; then
            dpi_args+="$arg "
        elif [[ "$arg" == "--rip-lib"* ]]; then
            lib_args+="$arg "
        fi
    done
    
    # Try with all modifications first
    if eval java -jar revanced-cli*.jar patch \
        -p *.rvp \
        $3 \
        --keystore=./src/_ks.keystore --force \
        --legacy-options=./src/options/$2.json $excludePatches$includePatches \
        --out=./release/$1-${archs[i]}-$2.apk \
        ./download/$1.apk; then
        return 0
    fi
    
    green_log "[!] Failed with all modifications, trying individual stripping"
    
    # Try with only DPI stripping if DPI args exist
    if [ ! -z "$dpi_args" ]; then
        green_log "[+] Attempting DPI stripping only"
        if eval java -jar revanced-cli*.jar patch \
            -p *.rvp \
            $dpi_args \
            --keystore=./src/_ks.keystore --force \
            --legacy-options=./src/options/$2.json $excludePatches$includePatches \
            --out=./release/$1-${archs[i]}-$2.apk \
            ./download/$1.apk; then
            return 0
        fi
    fi
    
    # Try with only lib stripping if lib args exist
    if [ ! -z "$lib_args" ]; then
        green_log "[+] Attempting lib stripping only"
        if eval java -jar revanced-cli*.jar patch \
            -p *.rvp \
            $lib_args \
            --keystore=./src/_ks.keystore --force \
            --legacy-options=./src/options/$2.json $excludePatches$includePatches \
            --out=./release/$1-${archs[i]}-$2.apk \
            ./download/$1.apk; then
            return 0
        fi
    fi
    
    # If all stripping attempts fail, try without any modifications
    green_log "[!] All stripping attempts failed, trying without modifications"
    if eval java -jar revanced-cli*.jar patch \
        -p *.rvp \
        --keystore=./src/_ks.keystore --force \
        --legacy-options=./src/options/$2.json $excludePatches$includePatches \
        --out=./release/$1-${archs[i]}-$2.apk \
        ./download/$1.apk; then
        return 0
    fi
    
    red_log "[-] Patching failed completely"
    exit 1
}
