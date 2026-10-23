#!/bin/bash

# Copyright (C) 2026 David Hedlund
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Description: Compare local core info files against buildbot binary availability
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

INFO_ARCHIVE_URL="https://github.com/libretro/libretro-super/releases/download/Latest/info.7z"
download_info_archive=true;
download_buildbot_index_files=true;
download_library_json=true;
copy_and_repair_index_files=true;
generate_cached_master_list=true;
generate_source_files=true;
generate_basic_core_names=true;
generate_core_overview=true;
validate_files=true;

# Build directory configuration
if [ -d build ]; then rm -rf build; fi

BUILD_DIR="./build"
BUILD_DOCS_DIR="$BUILD_DIR/docs"
PUBLISH_DOCS_DIR="./docs"
buildbot_dir="./downloads/buildbot"
master_index_json_cache="cache/core-index.json"

mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_DOCS_DIR"
mkdir -p "downloads"
mkdir -p "$buildbot_dir"
mkdir -p "cache"

# Defaults
MASTER_INFO_FILE="$BUILD_DIR/info_files_with_cores-full_info_filenames.txt"
MASTER_INFO_FILE_CORE_NAME="$BUILD_DIR/info_files_with_cores-core_names.txt"
MASTER_DOCUMENT_FILE="$BUILD_DIR/documents_with_cores-core_names.index"
MASTER_CORES_FILE="$BUILD_DIR/core_names.txt"
ALL_NAMES="$BUILD_DIR/all_base_filenames.txt"
CORES_REPORT="$BUILD_DIR/cores_report.json"

# Output Report Paths inside build/docs/
OVERVIEW_FILES_MD="$BUILD_DOCS_DIR/core-files.md"
OVERVIEW_OS_ARCH_MD="$BUILD_DOCS_DIR/os-architecture-support.md"
OVERVIEW_INFO_NO_CORES_MD="$BUILD_DOCS_DIR/info-files-without-cores.md"
OVERVIEW_DOCS_NO_CORES_MD="$BUILD_DOCS_DIR/doc-files-without-cores.md"
OVERVIEW_MASTER_MD="$BUILD_DOCS_DIR/all.md"

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:158.0) Gecko/20100101 Firefox/158.0"


# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --help|-h)
            usage
            ;;
        *) 
            echo "Unknown parameter: $1"
            usage 
            ;;
    esac
    shift
done


# List of buildbot URLs
URLS=(
    "https://buildbot.libretro.com/nightly/android/latest/arm64-v8a/"
    "https://buildbot.libretro.com/nightly/android/latest/armeabi/"
    "https://buildbot.libretro.com/nightly/android/latest/armeabi-v7a/"
    "https://buildbot.libretro.com/nightly/android/latest/x86/"
    "https://buildbot.libretro.com/nightly/android/latest/x86_64/"
    "https://buildbot.libretro.com/nightly/apple/ios/latest/"
    "https://buildbot.libretro.com/nightly/apple/ios9/latest/"
    "https://buildbot.libretro.com/nightly/apple/ios-arm64/latest/"
    "https://buildbot.libretro.com/nightly/apple/osx/arm64/latest/"
    "https://buildbot.libretro.com/nightly/apple/osx/ppc/latest/"
    "https://buildbot.libretro.com/nightly/apple/osx/universal/latest/"
    "https://buildbot.libretro.com/nightly/apple/osx/x86/latest/"
    "https://buildbot.libretro.com/nightly/apple/osx/x86_64/latest/"
    "https://buildbot.libretro.com/nightly/apple/tvos-arm64/latest/"
    "https://buildbot.libretro.com/nightly/dingux/mips32/latest/"
    "https://buildbot.libretro.com/nightly/dingux/mips32-odbeta/latest/"
    "https://buildbot.libretro.com/nightly/dingux/miyoo-arm32/latest/"
    "https://buildbot.libretro.com/nightly/dingux/retrofw-mips32/latest/"
    "https://buildbot.libretro.com/nightly/dingux/rs90-mips32-odbeta/latest/"
    "https://buildbot.libretro.com/nightly/linux/aarch64/latest/"
    "https://buildbot.libretro.com/nightly/linux/armhf/latest/"
    "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/"
    "https://buildbot.libretro.com/nightly/linux/x86/latest/"
    "https://buildbot.libretro.com/nightly/linux/x86_64/latest/"
    "https://buildbot.libretro.com/nightly/nintendo/3ds/latest/3dsx/"
    "https://buildbot.libretro.com/nightly/nintendo/3ds/latest/cia/"
    "https://buildbot.libretro.com/nightly/nintendo/ngc/latest/"
    "https://buildbot.libretro.com/nightly/nintendo/switch/libnx/latest/"
    "https://buildbot.libretro.com/nightly/nintendo/wii/latest/"
    "https://buildbot.libretro.com/nightly/nintendo/wiiu/latest/"
    "https://buildbot.libretro.com/nightly/playstation/ps2/latest/"
    "https://buildbot.libretro.com/nightly/playstation/psp/latest/"
    "https://buildbot.libretro.com/nightly/webos/armv7a/latest/"
    "https://buildbot.libretro.com/nightly/windows/x86/latest/"
    "https://buildbot.libretro.com/nightly/windows/x86_64/latest/"
)


time_elapsed() {
    local start_time=$1
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    echo "Markdown generated successfully in ${elapsed} seconds."
}


if [[ "$download_info_archive" = true ]]; then
    if curl -sL -A "$USER_AGENT" --output-dir "downloads" -O "$INFO_ARCHIVE_URL"; then
    filename="${INFO_ARCHIVE_URL##*/}"
    echo "[SUCCESS] Downloaded: downloads/$filename"
    else
    echo "[FAILED] Download error: $INFO_ARCHIVE_URL"
    fi
fi


if [[ "$download_library_json" = true ]]; then
    curl -s "https://api.github.com/repos/libretro/docs/contents/docs/library" | jq '.' > downloads/library.index
fi

if [[ "$download_buildbot_index_files" = true ]]; then
    echo "Building master core list from all platforms..."
    
    success_messages=()
    failure_messages=()

    for url in "${URLS[@]}"; do
        clean_url="${url%/}"
        arch_dir="${clean_url#*nightly/}"
        target_dir="$buildbot_dir/$arch_dir"

        mkdir -p "$target_dir" && echo "Created: $target_dir/"

        temp_file=$(mktemp)
        
        if curl -sLf -A "$USER_AGENT" "$url.index-extended" -o "$temp_file"; then
            if head -c 10 "$temp_file" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
                mv "$temp_file" "$target_dir/.index-extended"
                echo "[SUCCESS] $url.index-extended -> $target_dir/.index-extended"
                success_messages+=("$url.index-extended -> $target_dir/.index-extended")
            else
                rm -f "$temp_file"
                echo "[SKIPPED] $url.index-extended (Invalid format)"
                failure_messages+=("$url.index-extended (Invalid format)")
            fi
        else
            rm -f "$temp_file"
            echo "[FAILED]  $url.index-extended (Download error)"
            failure_messages+=("$url.index-extended (Download error)")
        fi
    done

    echo ""
    echo "=== Failed / Skipped Downloads Summary ==="
    if [ ${#failure_messages[@]} -gt 0 ]; then
        for msg in "${failure_messages[@]}"; do
            echo "  [FAILED/SKIPPED] $msg"
        done
    else
        echo "  (None)"
    fi
fi


if [[ "$copy_and_repair_index_files" = true ]]; then 
    cp -r downloads/buildbot/ build/
    
    echo "Repair buildbot index files so they can be converted to JSON later:"
    echo "------------------------------------"

    regex='^.{1,9}$'

    while IFS= read -r -d '' filepath; do
        matches=$(grep -E "$regex" "$filepath")
        
        if [[ -n "$matches" ]]; then
            echo "$filepath"
            echo "$matches"
            sed -i -E "/$regex/d" "$filepath" && echo "Removed those lines"
        fi
    done < <(find build -type f -name ".index-extended" -print0 | LC_ALL=C sort -z)
fi

if [[ "$generate_cached_master_list" = true ]]; then
    if [[ "$copy_and_repair_index_files" = false ]]; then
        echo "Error: generate_cached_master_list requires copy_and_repair_index_files to be true." >&2
        echo "Set copy_and_repair_index_files to true." >&2
        exit 1
    fi

    echo ""
    echo "Generate $master_index_json_cache:"
    echo "------------------------------------"
    
    if [[ -f "$master_index_json_cache" ]]; then
        rm "$master_index_json_cache"
    fi

    while IFS= read -r -d '' filepath; do
        echo "Processing: $filepath"

        clean_path="${filepath#build/buildbot/}"
        clean_path="${clean_path%.index-extended}"
        webpath="https://buildbot.libretro.com/nightly/$clean_path"

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue

            read -r file_date file_commit file_name <<< "$line"

            jq -nc \
                --arg date "$file_date" \
                --arg commit "$file_commit" \
                --arg name "$file_name" \
                --arg webpath "$webpath" \
                '{date: $date, commit: $commit, name: $name, url: $webpath}' >> "$master_index_json_cache"

        done < "$filepath"

    done < <(find build -type f -name ".index-extended" -print0 | LC_ALL=C sort -z)

    tmp_json=$(mktemp)
    jq -s '.' "$master_index_json_cache" > "$tmp_json" && mv "$tmp_json" "$master_index_json_cache"
    
    chmod -w "$master_index_json_cache"
    echo "Master list generated at cache/core-index.json"
fi

if [[ "$generate_basic_core_names" = true ]]; then 
    jq -r '.[].name' "$master_index_json_cache" >> "$MASTER_CORES_FILE"
    sed -i 's/_libretro.*//' "$MASTER_CORES_FILE"
    sort -u "$MASTER_CORES_FILE" -o "$MASTER_CORES_FILE"
    
    curl -sL "https://api.github.com/repos/libretro/libretro-super/contents/dist/info" | jq -r '.[].name' | sort > "$MASTER_INFO_FILE"
    cp "$MASTER_INFO_FILE" "$MASTER_INFO_FILE_CORE_NAME"
    sed -i 's/_libretro.*//' "$MASTER_INFO_FILE_CORE_NAME"

    if [[ ! -s "$MASTER_CORES_FILE" ]]; then
    echo "Error: Master core list is empty. Scraping failed or no .zip files found."
    rm "$MASTER_CORES_FILE"
    exit 1
    fi
fi


if [[ "$generate_source_files" = true ]]; then
    curl -s "https://api.github.com/repos/libretro/docs/contents/docs/library" | jq '.' > downloads/library.index
    jq -r '.. | objects | .name? | select(. != null) | sub("\\.md$"; "")' downloads/library.index > "$MASTER_DOCUMENT_FILE"
    
    {
    cat "$MASTER_DOCUMENT_FILE"
    cat "$MASTER_INFO_FILE_CORE_NAME"
    cat "$MASTER_CORES_FILE"
    } | sort -u > "$ALL_NAMES"

    jq -n \
        --rawfile all "$ALL_NAMES" \
        --rawfile cores "$MASTER_CORES_FILE" \
        --rawfile info "$MASTER_INFO_FILE_CORE_NAME" \
        --rawfile docs "$MASTER_DOCUMENT_FILE" \
        '
  ($all | split("\n") | map(select(length > 0))) as $all_names |
  ($cores | split("\n") | map(select(length > 0)) | map({(.): true}) | add // {}) as $core_map |
  ($info | split("\n") | map(select(length > 0)) | map({(.): true}) | add // {}) as $info_map |
  ($docs | split("\n") | map(select(length > 0)) | map({(.): true}) | add // {}) as $doc_map |
  
  $all_names | map({
    name: .,
    core: ($core_map[.] // false),
    info: ($info_map[.] // false),
    doc:  ($doc_map[.] // false)
  })
  ' > "$CORES_REPORT"
fi


if [[ "$generate_core_overview" = true ]]; then

    echo "---------------------------------------------------"
    echo "Generating overview: $OVERVIEW_FILES_MD"
    {
        start_time=$(date +%s)
        echo "### Core Files"
        
        jq -r '
  "| Core | Has info | Has doc |",
  "|---|---|---|",
  (.[] | select(.core == true) | 
    "| \(.name) | [" + (if .info then "✅ Yes" else "❌ No" end) + "](https://github.com/libretro/libretro-super/tree/master/dist/info/\(.name)_libretro.info) | [" + (if .doc then "✅ Yes" else "❌ No" end) + "](https://github.com/libretro/docs/tree/master/docs/library/\(.name).md) |"
  )
' "$CORES_REPORT"
    } > "$OVERVIEW_FILES_MD"

    time_elapsed "$start_time"


    echo "---------------------------------------------------"
    echo "Generating overview: $OVERVIEW_OS_ARCH_MD"

    {
        start_time=$(date +%s)
        echo "### OS and Architecture Support Matrix"
        full_table=$(mktemp)

        {
            echo "| Core | Android arm64-v8a | Android armeabi | Android armeabi-v7a | Android x86 | Android x86_64 | Apple iOS | Apple iOS 9 | Apple iOS arm64 | Apple OSX arm64 | Apple OSX ppc | Apple OSX universal | Apple OSX x86 | Apple OSX x86_64 | Apple tvOS arm64 | Dingux mips32 | Dingux mips32 odbeta | Dingux miyoo arm32 | Dingux retrofw mips32 | Dingux rs90 mips32 odbeta | Linux aarch64 | Linux armhf | Linux armv7 neon hf | Linux x86 | Linux x86_64 | Nintendo 3DS (3dsx) | Nintendo 3DS (cia) | Nintendo GameCube | Nintendo Switch (libnx) | Nintendo Wii | Nintendo Wii U | PlayStation PS2 | PlayStation PSP | WebOS armv7a | Windows x86 | Windows x86_64 |"
            echo "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"

            targets=(
            "https://buildbot.libretro.com/nightly/android/latest/arm64-v8a/"
            "https://buildbot.libretro.com/nightly/android/latest/armeabi/"
            "https://buildbot.libretro.com/nightly/android/latest/armeabi-v7a/"
            "https://buildbot.libretro.com/nightly/android/latest/x86/"
            "https://buildbot.libretro.com/nightly/android/latest/x86_64/"
            "https://buildbot.libretro.com/nightly/apple/ios/latest/"
            "https://buildbot.libretro.com/nightly/apple/ios9/latest/"
            "https://buildbot.libretro.com/nightly/apple/ios-arm64/latest/"
            "https://buildbot.libretro.com/nightly/apple/osx/arm64/latest/"
            "https://buildbot.libretro.com/nightly/apple/osx/ppc/latest/"
            "https://buildbot.libretro.com/nightly/apple/osx/universal/latest/"
            "https://buildbot.libretro.com/nightly/apple/osx/x86/latest/"
            "https://buildbot.libretro.com/nightly/apple/osx/x86_64/latest/"
            "https://buildbot.libretro.com/nightly/apple/tvos-arm64/latest/"
            "https://buildbot.libretro.com/nightly/dingux/mips32/latest/"
            "https://buildbot.libretro.com/nightly/dingux/mips32-odbeta/latest/"
            "https://buildbot.libretro.com/nightly/dingux/miyoo-arm32/latest/"
            "https://buildbot.libretro.com/nightly/dingux/retrofw-mips32/latest/"
            "https://buildbot.libretro.com/nightly/dingux/rs90-mips32-odbeta/latest/"
            "https://buildbot.libretro.com/nightly/linux/aarch64/latest/"
            "https://buildbot.libretro.com/nightly/linux/armhf/latest/"
            "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/"
            "https://buildbot.libretro.com/nightly/linux/x86/latest/"
            "https://buildbot.libretro.com/nightly/linux/x86_64/latest/"
            "https://buildbot.libretro.com/nightly/nintendo/3ds/latest/3dsx/"
            "https://buildbot.libretro.com/nightly/nintendo/3ds/latest/cia/"
            "https://buildbot.libretro.com/nightly/nintendo/ngc/latest/"
            "https://buildbot.libretro.com/nightly/nintendo/switch/libnx/latest/"
            "https://buildbot.libretro.com/nightly/nintendo/wii/latest/"
            "https://buildbot.libretro.com/nightly/nintendo/wiiu/latest/"
            "https://buildbot.libretro.com/nightly/playstation/ps2/latest/"
            "https://buildbot.libretro.com/nightly/playstation/psp/latest/"
            "https://buildbot.libretro.com/nightly/webos/armv7a/latest/"
            "https://buildbot.libretro.com/nightly/windows/x86/latest/"
            "https://buildbot.libretro.com/nightly/windows/x86_64/latest/"
            )

            while IFS= read -r core; do
                printf "| %s " "$core"
                
                declare -A target_names=()

                while IFS=$'\t' read -r u n; do
                    for target in "${targets[@]}"; do
                        if [[ "$u" == "$target"* ]]; then
                            target_names["$target"]="$n"
                        fi
                    done
                done < <(jq -r --arg core "$core" '.[] | select(.name | test("^" + $core + "_libretro")) | "\(.url)\t\(.name)"' "$master_index_json_cache")

                for target in "${targets[@]}"; do
                    if [ -n "${target_names["$target"]}" ]; then
                        printf "| [✅ Yes](%s%s) " "$target" "${target_names["$target"]}"
                    else
                        printf "| ❌ No "
                    fi
                done
                
                echo "|"
                
            done < "$MASTER_CORES_FILE"
        } > "$full_table"

        extract_cols() {
            local start="$1"
            local end="$2"
            local prefix="$3"

            awk -F'|' -v s="$start" -v e="$end" -v p="$prefix" '
            NR==1 {
                printf "|" $2 "|"
                for(i=s; i<=e; i++) {
                    val = $i
                    if (p != "") {
                        sub("^ " p " ", " ", val)
                    }
                    printf val "|"
                }
                print ""
            }
            NR==2 {
                printf "|" $2 "|"
                for(i=s; i<=e; i++) printf $i "|"
                print ""
            }
            NR>2 {
                if (NF < 3) next;
                printf "|" $2 "|"
                for(i=s; i<=e; i++) printf $i "|"
                print ""
            }' "$full_table"
        }

        echo "#### Android"
        echo ""
        extract_cols 3 7 "Android"
        echo ""

        echo "#### Apple"
        echo ""
        extract_cols 8 16 "Apple"
        echo ""

        echo "#### Dingux"
        echo ""
        extract_cols 17 21 "Dingux"
        echo ""

        echo "#### Linux"
        echo ""
        extract_cols 22 26 "Linux"
        echo ""

        echo "#### Nintendo"
        echo ""
        extract_cols 27 32 "Nintendo"
        echo ""

        echo "#### PlayStation"
        echo ""
        extract_cols 33 34 "PlayStation"
        echo ""

        echo "#### WebOS"
        echo ""
        extract_cols 35 35 "WebOS"
        echo ""

        echo "#### Windows"
        echo ""
        extract_cols 36 37 "Windows"
        echo ""

        rm -f "$full_table"
    } > "$OVERVIEW_OS_ARCH_MD"

    time_elapsed "$start_time"


    echo "---------------------------------------------------"
    echo "Generating overview: $OVERVIEW_INFO_NO_CORES_MD"
    {
        echo "### Info Files Without Cores"
        jq -r '["Info"], ( [.[] | select(.core == false and .info == true)] | sort_by(.name)[] | ["[\(.name)_libretro.info](https://github.com/libretro/libretro-super/tree/master/dist/info/\(.name)_libretro.info)"] ) | @tsv' "$CORES_REPORT" | awk -F'\t' 'NR==1 {print "| " $1 " |\n| --- |"} NR>1 {print "| " $1 " |"}'
    } > "$OVERVIEW_INFO_NO_CORES_MD"


    echo "---------------------------------------------------"
    echo "Generating overview: $OVERVIEW_DOCS_NO_CORES_MD"
    {
        echo "### Document Files Without Cores"
        jq -r '["Doc"], ( [.[] | select(.core == false and .doc == true)] | sort_by(.name)[] | ["[\(.name).md](https://github.com/libretro/docs/tree/master/docs/library/\(.name).md)"] ) | @tsv' "$CORES_REPORT" | awk -F'\t' 'NR==1 {print "| " $1 " |\n| --- |"} NR>1 {print "| " $1 " |"}'
    } > "$OVERVIEW_DOCS_NO_CORES_MD"


   
    echo "---------------------------------------------------"
    echo "Generating overview: $OVERVIEW_MASTER_MD"
    {
        echo "# Libretro Overview"
        echo "* [Cores](#cores)
   - [Core files](#core-files)
   - [Core OS and architecture support](#core-os-and-architecture-support)
     - [Android](#android)
     - [Apple](#apple)
     - [Dingux](#dingux)
     - [Linux](#linux)
     - [Nintendo](#nintendo)
     - [PlayStation](#playstation)
     - [WebOS](#webos)
     - [Windows](#windows)
- [Files without cores](#files-without-cores)
   - [Info files without cores](#info-files-without-cores)
   - [Document files without cores](#document-files-without-cores)"
        echo ""
        echo "## Cores"
        echo ""
        cat "$OVERVIEW_FILES_MD"
        echo ""
        cat "$OVERVIEW_OS_ARCH_MD"
        echo ""
        echo "# Files without cores"
        echo ""
        cat "$OVERVIEW_INFO_NO_CORES_MD"
        echo ""
        cat "$OVERVIEW_DOCS_NO_CORES_MD"
    } > "$OVERVIEW_MASTER_MD"

    # This processes all individual .md files in build/docs/ (except all.md)
    # and strips the leading ## to correct their header levels.
    echo "Shift header levels down in individual MD files..."
    find build/docs/ -name "*.md" ! -name "all.md" -exec sed -i 's/^##//' {} +
    
    # Sync step to publish fresh reports into root docs/ (removing stale files)
    echo "---------------------------------------------------"
    echo "Publishing and syncing reports to $PUBLISH_DOCS_DIR..."
    mkdir -p "$PUBLISH_DOCS_DIR"

    if command -v rsync >/dev/null 2>&1; then
        rsync -av --delete "$BUILD_DOCS_DIR/" "$PUBLISH_DOCS_DIR/"
    else
        rm -rf "$PUBLISH_DOCS_DIR"
        mkdir -p "$PUBLISH_DOCS_DIR"
        cp -r "$BUILD_DOCS_DIR/"* "$PUBLISH_DOCS_DIR/"
    fi

    echo "[SUCCESS] Documentation published to $PUBLISH_DOCS_DIR/"
fi

exit
