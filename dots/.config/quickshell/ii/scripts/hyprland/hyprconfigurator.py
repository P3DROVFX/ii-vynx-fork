#!/usr/bin/env -S /bin/sh -c "source \$(eval echo \$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec python -E \"\$0\" \"\$@\""
import argparse, re, os, tempfile

def format_value(value):
    if value in ('true', 'false'): return value
    try:
        float(value)
        return value
    except ValueError: return f'"{value}"'

def build_nested_structure(key_parts, value):
    if len(key_parts) == 1: return f'{key_parts[0]}={format_value(value)}'
    return f'{key_parts[0]}={{{build_nested_structure(key_parts[1:], value)}}}'

def generate_config_line(key, value):
    return f'hl.config({{{build_nested_structure(key.split(":"), value)}}})\n'

def edit_hyprland_config(file_path, set_args, reset_args):
    lines = open(file_path, 'r').readlines() if os.path.exists(file_path) else []
    set_dict = {k: v for k, v in set_args} if set_args else {}
    reset_set = set(reset_args) if reset_args else set()
    new_lines, found_keys, patterns = [], set(), {}

    for k in list(set_dict.keys()) + list(reset_set):
        parts = k.split(':')
        if len(parts) > 1:
            patterns[k] = re.compile(rf'^\s*hl\.config\(\{{\s*{"\{".join([rf"\s*{re.escape(p)}\s*=" for p in parts])}')
        else:
            patterns[k] = re.compile(rf'^\s*hl\.config\(\{{\s*{re.escape(parts[0])}\s*=')

    for line in lines:
        if any(patterns[k].match(line) for k in reset_set): continue
        matched = False
        for k, v in set_dict.items():
            if patterns[k].match(line):
                new_lines.append(generate_config_line(k, v))
                found_keys.add(k)
                matched = True
                break
        if not matched: new_lines.append(line)

    for k, v in set_dict.items():
        if k not in found_keys:
            if new_lines and not new_lines[-1].endswith('\n'): new_lines[-1] += '\n'
            new_lines.append(generate_config_line(k, v))

    os.makedirs(os.path.dirname(os.path.abspath(file_path)), exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=os.path.dirname(os.path.abspath(file_path)), delete=False) as tmp:
        tmp.writelines(new_lines)
        tmp_name = tmp.name
    if os.path.exists(file_path): os.chmod(tmp_name, os.stat(file_path).st_mode)
    else: os.chmod(tmp_name, 0o644)
    os.replace(tmp_name, file_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", default="~/.config/hypr/hyprland.conf")
    parser.add_argument("--set", nargs=2, action="append")
    parser.add_argument("--reset", action="append")
    args = parser.parse_args()
    f = os.path.expanduser(args.file)
    s, r = [], []
    for k, v in (args.set or []):
        if v == "[[EMPTY]]": r.append(k)
        else: s.append((k, v))
    if s or r or (args.reset): edit_hyprland_config(f, s, r + (args.reset or []))
