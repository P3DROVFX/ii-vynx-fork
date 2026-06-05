#!/usr/bin/env bash

PRESETS_DIR="$HOME/.config/illogical-impulse/presets"
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$PRESETS_DIR"

action=$1
name=$2

case $action in
    save)
        if [[ -z "$name" ]]; then exit 1; fi
        cp "$CONFIG_FILE" "$PRESETS_DIR/$name.json"
        
        # Also copy the wallpaper if configured
        wall_path=$(jq -r '.background.wallpaperPath // ""' "$CONFIG_FILE" 2>/dev/null)
        if [[ -f "$wall_path" ]]; then
            ext="${wall_path##*.}"
            cp "$wall_path" "$PRESETS_DIR/$name.$ext"
        fi
        ;;
    load)
        if [[ -z "$name" ]]; then exit 1; fi
        if [[ -f "$PRESETS_DIR/$name.json" ]]; then
            # Use python helper to expand paths and fallbacks
            python3 "$SCRIPTS_DIR/presets_helper.py" expand "$PRESETS_DIR/$name.json" "$CONFIG_FILE" "$PRESETS_DIR" "$name"
            
            # Apply wallpaper and colors from the newly loaded config
            env -u LD_LIBRARY_PATH -u PYTHONHOME -u PYTHONPATH PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH" "$SCRIPTS_DIR/colors/switchwall.sh" --noswitch > /tmp/presets_switchwall.log 2>&1 &
        fi
        ;;
    delete)
        if [[ -z "$name" ]]; then exit 1; fi
        rm -f "$PRESETS_DIR/$name.json"
        # Delete any associated wallpaper file
        for file in "$PRESETS_DIR/$name".*; do
            if [[ -f "$file" && "${file##*.}" != "json" ]]; then
                rm -f "$file"
            fi
        done
        ;;
    list)
        python3 "$SCRIPTS_DIR/presets_helper.py" list "$PRESETS_DIR"
        ;;
    export)
        if [[ -z "$name" ]]; then exit 1; fi
        if [[ ! -f "$PRESETS_DIR/$name.json" ]]; then exit 1; fi
        
        if command -v zenity >/dev/null; then
            DEST_ZIP=$(zenity --file-selection --save --confirm-overwrite --filename="$HOME/${name}.zip" --file-filter="ZIP | *.zip" 2>/dev/null)
        else
            DEST_ZIP=$(kdialog --getsavefilename "$HOME/${name}.zip" "*.zip" 2>/dev/null)
        fi
        
        if [[ -n "$DEST_ZIP" ]]; then
            # If the user selected .zip but extension wasn't appended automatically:
            if [[ "$DEST_ZIP" != *.zip ]]; then
                DEST_ZIP="${DEST_ZIP}.zip"
            fi
            
            TMP_DIR=$(mktemp -d /tmp/preset_export_XXXXXX)
            
            # Copy and sanitize JSON config
            cp "$PRESETS_DIR/$name.json" "$TMP_DIR/config.json"
            python3 "$SCRIPTS_DIR/presets_helper.py" sanitize "$TMP_DIR/config.json" "$TMP_DIR/config.json"
            
            # Find and copy wallpaper if it exists
            # Look for MyPreset.* excluding .json and .zip
            for file in "$PRESETS_DIR/$name".*; do
                if [[ -f "$file" ]]; then
                    ext="${file##*.}"
                    if [[ "$ext" != "json" && "$ext" != "zip" ]]; then
                        cp "$file" "$TMP_DIR/wallpaper.$ext"
                        break
                    fi
                fi
            done
            
            # Zip everything
            (cd "$TMP_DIR" && zip -r "$DEST_ZIP" .)
            
            # Cleanup
            rm -rf "$TMP_DIR"
        fi
        ;;
    import)
        if command -v zenity >/dev/null; then
            FILE=$(zenity --file-selection --file-filter="Presets (*.zip *.json) | *.zip *.json" 2>/dev/null)
        else
            FILE=$(kdialog --getopenfilename "$HOME" "*.zip *.json" 2>/dev/null)
        fi
        
        if [[ -n "$FILE" && -f "$FILE" ]]; then
            preset_name=$(basename "$FILE" | sed 's/\.[^.]*$//')
            ext="${FILE##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$ext" == "json" ]]; then
                # Clean/sanitize paths even on raw JSON import to be safe
                mkdir -p "$PRESETS_DIR"
                python3 "$SCRIPTS_DIR/presets_helper.py" sanitize "$FILE" "$PRESETS_DIR/$preset_name.json"
                echo 'success'
            elif [[ "$ext" == "zip" ]]; then
                TMP_DIR=$(mktemp -d /tmp/preset_import_XXXXXX)
                unzip -o "$FILE" -d "$TMP_DIR" >/dev/null
                
                # Check for config file
                config_json=""
                if [[ -f "$TMP_DIR/config.json" ]]; then
                    config_json="$TMP_DIR/config.json"
                else
                    # Fallback to any json in zip
                    for f in "$TMP_DIR"/*.json; do
                        if [[ -f "$f" ]]; then
                            config_json="$f"
                            break
                        fi
                    done
                fi
                
                if [[ -n "$config_json" ]]; then
                    mkdir -p "$PRESETS_DIR"
                    # Sanitize paths when importing config
                    python3 "$SCRIPTS_DIR/presets_helper.py" sanitize "$config_json" "$PRESETS_DIR/$preset_name.json"
                    
                    # Find wallpaper
                    for f in "$TMP_DIR"/*; do
                        if [[ -f "$f" ]]; then
                            f_ext="${f##*.}"
                            f_ext=$(echo "$f_ext" | tr '[:upper:]' '[:lower:]')
                            if [[ "$f_ext" != "json" && "$f_ext" != "zip" ]]; then
                                cp "$f" "$PRESETS_DIR/$preset_name.$f_ext"
                                break
                            fi
                        fi
                    done
                    echo 'success'
                fi
                rm -rf "$TMP_DIR"
            fi
        fi
        ;;
esac
