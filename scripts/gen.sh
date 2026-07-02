#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Target paths
TEE_SRC_DIR="out/vendor/tee"
TARGET_TEE_FILE="${TEE_SRC_DIR}/00000000-0000-0000-0000-000048444350"
RC_FILE_PATH="prebuilts/tee_a05m.rc"

extract_tee_info() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "Error: File not found -> $file_path" >&2
        return 1
    fi

    # 1. Run strings and grep for the pattern (equivalent to Python's regex check)
    # 2. Extract only the first match and truncate to 13 characters
    local full_string
    full_string=$(strings "$file_path" | grep -oE 'A055[A-Z0-9]+' | head -n 1)

    if [ -z "$full_string" ]; then
        echo "Error: Bootloader string parsing failed." >&2
        return 1
    fi

    local bootloader="${full_string:0:13}"

    if [ ${#bootloader} -lt 9 ]; then
        echo "Error: Bootloader string too short." >&2
        return 1
    fi

    # Dynamically determine model and suffix using Bash string manipulation
    # 5th character (index 4)
    local model_char="${bootloader:4:1}" 
    # 9th character (index 8)
    local tee_char="${bootloader:8:1}"   

    # Construct and return variables (printed to stdout so the caller can capture them)
    local model="SM-A055${model_char}"
    local subfolder="TEE_${tee_char}"

    echo "$model $bootloader $subfolder"
}

update_rc_file() {
    local rc_path="$1"
    local model="$2"
    local bootloader="$3"
    local source_dir="$4"

    # Multiline string block for the .rc entry
    local rc_entry="
# ${model} - ${bootloader}
on early-fs && property:ro.boot.em.model=${model} && property:ro.boot.bootloader=${bootloader}
    mount none ${source_dir} /vendor/tee bind
"

    # Append to the RC file safely
    if echo "$rc_entry" >> "$rc_path"; then
        echo "Successfully appended entry to ${rc_path}:"
        echo "$rc_entry" | sed '/^$/d' # Prints the entry without extra leading/trailing whitespace
    else
        echo "Failed to write to RC file" >&2
        return 1
    fi
}

main() {
    # 1. Dynamically parse the binary
    # Captures the space-separated output from the extract function into a Bash array
    local info
    info=($(extract_tee_info "$TARGET_TEE_FILE")) || exit 1

    local model="${info[0]}"
    local bootloader="${info[1]}"
    local subfolder="${info[2]}"

    if [ -n "$model" ] && [ -n "$bootloader" ] && [ -n "$subfolder" ]; then
        # 2. Build the unified storage path for the .rc rule
        local source_dir="/vendor/tee/${model}/${subfolder}"

        # 3. Update the .rc rule
        update_rc_file "$RC_FILE_PATH" "$model" "$bootloader" "$source_dir"

        # 4. Create destination directory structure safely (akin to mkdir(parents=True))
        local dest_dir="prebuilts/${model}/${subfolder}"
        mkdir -p "$dest_dir"

        # 5. Copy all files from out/vendor/tee/* into prebuilts/{model}/{subfolder}
        echo "Copying TEE binaries to ${dest_dir}..."
        
        # Using cp -r allows contents to merge if the directory already exists
        if cp -r "${TEE_SRC_DIR}/." "$dest_dir/"; then
            echo "Copy completed successfully."
        else
            echo "Failed to copy files." >&2
            exit 1
        fi
    fi
}

main
