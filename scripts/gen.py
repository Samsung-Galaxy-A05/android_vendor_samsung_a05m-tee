import os
import re
import shutil
from pathlib import Path

def extract_tee_info(tee_file_path):
    """
    Reads the TEE binary file, extracts the bootloader string,
    and dynamically determines the model (5th char) and TEE folder suffix (9th char).
    """
    if not os.path.exists(tee_file_path):
        print(f"Error: File not found -> {tee_file_path}")
        return None, None, None

    # Pattern to match 'A055' followed by bootloader alphanumeric characters
    pattern = re.compile(b'(A055[A-Z0-9]+)')
    
    with open(tee_file_path, 'rb') as f:
        content = f.read()
        matches = pattern.findall(content)
        
        if matches:
            # Decode the first match, e.g., "A055MUBSIDZE11"
            full_string = matches[0].decode('utf-8', errors='ignore')
            
            # Truncate to the standard 13-character bootloader string
            bootloader = full_string[:13] 
            
            if len(bootloader) >= 9:
                # 5th character (index 4) -> e.g., 'M' or 'F'
                model_char = bootloader[4]
                # 9th character (index 8) -> e.g., 'I'
                tee_char = bootloader[8]
                
                # Construct variables
                model = f"SM-A055{model_char}"
                subfolder_suffix = f"TEE_{tee_char}"
                
                return model, bootloader, subfolder_suffix
            
    print("Error: Bootloader string parsing failed or string too short.")
    return None, None, None

def update_rc_file(rc_path, model, bootloader, source_dir):
    """
    Appends the formatted mount rule to the specified .rc file.
    """
    rc_entry = (
        f"\n"
        f"# {model} - {bootloader}"
        f"\n"
        f"on early-fs && property:ro.boot.em.model={model} && property:ro.boot.bootloader={bootloader}\n"
        f"    mount none {source_dir} /vendor/tee bind\n"
    )
    
    try:
        with open(rc_path, 'a') as rc_file:
            rc_file.write(rc_entry)
        print(f"Successfully appended entry to {rc_path}:")
        print(rc_entry.strip())
    except Exception as e:
        print(f"Failed to write to RC file: {e}")

def main():
    # Target paths
    tee_src_dir = "out/vendor/tee"
    target_tee_file = os.path.join(tee_src_dir, "00000000-0000-0000-0000-000048444350")
    rc_file_path = "prebuilts/tee_a05m.rc"
    
    # 1. Dynamically parse the binary
    model, bootloader, subfolder = extract_tee_info(target_tee_file)
    
    if model and bootloader and subfolder:
        # 2. Build the unified storage path for the .rc rule
        source_dir = f"/vendor/tee/{model}/{subfolder}"
        
        # 3. Update the .rc rule
        update_rc_file(rc_file_path, model, bootloader, source_dir)

        # 4. Create destination directory structure safely
        dest_dir = Path(f"prebuilts/{model}/{subfolder}")
        dest_dir.mkdir(parents=True, exist_ok=True)
        
        # 5. Copy all files from out/vendor/tee/* into prebuilts/{model}/{subfolder}
        print(f"Copying TEE binaries to {dest_dir}...")
        try:
            # We iterate through the directory to copy contents into the existing/new folder.
            # Using dirs_exist_ok=True (Python 3.8+) allows merging if files already exist.
            shutil.copytree(tee_src_dir, dest_dir, dirs_exist_ok=True)
            print("Copy completed successfully.")
        except Exception as e:
            print(f"Failed to copy files: {e}")

if __name__ == "__main__":
    main()
