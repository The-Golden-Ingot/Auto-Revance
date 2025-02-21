#!/bin/bash

mkdir ./release ./download

# Download APKs using APKMD CLI
setup_apkmd() {
    # Download and setup APKMD
    wget -q -O ./apkmd https://github.com/tanishqmanuja/apkmirror-downloader/releases/latest/download/apkmd
    chmod +x ./apkmd
    APKMD="./apkmd"
}

#Setup pup for download apk files
wget -qO- "https://api.github.com/repos/ericchiang/pup/releases/latest" \
    | jq -r '.assets[] | select(.name | endswith("linux_amd64.zip")) | .browser_download_url' \
    | wget -q -i - -O ./pup.zip
unzip "./pup.zip" -d "./" > /dev/null 2>&1
pup="./pup"

# Add APKMD setup
setup_apkmd

#Setup APKEditor for install combine split apks
wget -qO- "https://api.github.com/repos/REAndroid/APKEditor/releases/latest" \
    | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' \
    | wget -q -i - -O ./APKEditor.jar
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

# Download APKs using APKMD CLI
setup_apkmd() {
    # Download and setup APKMD
    wget -q -O ./apkmd https://github.com/tanishqmanuja/apkmirror-downloader/releases/latest/download/apkmd
    chmod +x ./apkmd
    APKMD="./apkmd"
}

get_apk() {
    # Parse organization and repo from the APKMirror path
    IFS='/' read -r org repo <<< "$4"
    
    # Build APKMD command arguments
    local args=(
        "download"
        "$org"  # First required argument
        "$repo" # Second required argument
        "--out-dir" "./download"
    )
    
    # Add version if available
    [ -n "$version" ] && args+=("--version" "$version")
    
    # Add architecture filter if specified (arm64-v8a, armeabi-v7a, etc)
    [ -n "$6" ] && args+=("--arch" "$6")
    
    # Add DPI filter if specified (xxhdpi, etc)
    [ -n "$7" ] && args+=("--dpi" "$7")
    
    # Set type (apk or bundle)
    if [[ $5 == "Bundle"* ]]; then
        args+=("--type" "bundle")
    else
        args+=("--type" "apk")
    fi

    # Set output filename
    local base_apk="$2.apk"
    [ "$5" == "Bundle"* ] && base_apk="$2.apkm"
    args+=("--outfile" "$2")

    green_log "[+] Downloading $3 using APKMD: ${args[*]}"
    
    # Execute APKMD command
    if $APKMD "${args[@]}"; then
        green_log "[+] Successfully downloaded $2"
    else
        red_log "[-] Failed to download $2"
        exit 1
    fi

    # Handle bundle files
    if [[ $5 == "Bundle" ]]; then
        green_log "[+] Merging splits apk to standalone apk"
        java -jar $APKEditor m -i "./download/$2.apkm" -o "./download/$2.apk" > /dev/null 2>&1
    elif [[ $5 == "Bundle_extract" ]]; then
        unzip "./download/$base_apk" -d "./download/$(basename "$base_apk" .apkm)" > /dev/null 2>&1
    fi
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
