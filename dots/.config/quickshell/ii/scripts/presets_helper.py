#!/usr/bin/env python3
import json
import os
import sys
import glob

def sanitize_val(val, home_dir):
    if isinstance(val, dict):
        return {k: sanitize_val(v, home_dir) for k, v in val.items()}
    elif isinstance(val, list):
        return [sanitize_val(x, home_dir) for x in val]
    elif isinstance(val, str):
        if home_dir and home_dir in val:
            return val.replace(home_dir, '$HOME')
        return val
    return val

def sanitize(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 1. Clean themed icons settings
    if 'appearance' in data:
        if isinstance(data['appearance'], dict):
            if 'icons' in data['appearance'] and isinstance(data['appearance']['icons'], dict):
                data['appearance']['icons']['enableThemed'] = False
            data['appearance']['iconTheme'] = ""
            
    # 2. Sanitize home paths
    home_dir = os.environ.get('HOME', '')
    if home_dir.endswith('/'):
        home_dir = home_dir[:-1]
        
    data = sanitize_val(data, home_dir)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)

def expand_val(val, home_dir):
    if isinstance(val, dict):
        return {k: expand_val(v, home_dir) for k, v in val.items()}
    elif isinstance(val, list):
        return [expand_val(x, home_dir) for x in val]
    elif isinstance(val, str):
        if '$HOME' in val:
            return val.replace('$HOME', home_dir)
        return val
    return val

def expand(input_path, output_path, presets_dir, preset_name):
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    home_dir = os.environ.get('HOME', '')
    if home_dir.endswith('/'):
        home_dir = home_dir[:-1]
        
    data = expand_val(data, home_dir)
    
    # Check if background.wallpaperPath exists
    bg = data.get('background', {})
    if isinstance(bg, dict):
        wall_path = bg.get('wallpaperPath', '')
        if not wall_path or not os.path.exists(wall_path):
            # Check for fallback file in presets_dir
            fallback = find_wallpaper_fallback(presets_dir, preset_name)
            if fallback:
                bg['wallpaperPath'] = fallback
                data['background'] = bg
                
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)

def find_wallpaper_fallback(presets_dir, preset_name):
    pattern = os.path.join(presets_dir, f"{preset_name}.*")
    for filepath in glob.glob(pattern):
        ext = os.path.splitext(filepath)[1].lower()
        if ext not in ('.json', '.zip'):
            return filepath
    return None

def list_presets(presets_dir):
    home_dir = os.environ.get('HOME', '')
    if home_dir.endswith('/'):
        home_dir = home_dir[:-1]
        
    pattern = os.path.join(presets_dir, "*.json")
    # Sort presets by name case-insensitively
    preset_files = sorted(glob.glob(pattern), key=lambda x: os.path.basename(x).lower())
    for json_path in preset_files:
        filename = os.path.basename(json_path)
        preset_name = os.path.splitext(filename)[0]
        
        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception:
            continue
            
        bg = data.get('background', {})
        wall_path = ''
        if isinstance(bg, dict):
            wall_path = bg.get('wallpaperPath', '')
            if wall_path:
                wall_path = wall_path.replace('$HOME', home_dir)
                
        if not wall_path or not os.path.exists(wall_path):
            fallback = find_wallpaper_fallback(presets_dir, preset_name)
            if fallback:
                wall_path = fallback
                
        print(json.dumps({"name": preset_name, "wallpaper": wall_path}))

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
        
    action = sys.argv[1]
    if action == 'sanitize':
        if len(sys.argv) < 4:
            sys.exit(1)
        sanitize(sys.argv[2], sys.argv[3])
    elif action == 'expand':
        if len(sys.argv) < 6:
            sys.exit(1)
        expand(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    elif action == 'list':
        if len(sys.argv) < 3:
            sys.exit(1)
        list_presets(sys.argv[2])
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
