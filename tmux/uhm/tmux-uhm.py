#!/usr/bin/env python3

import sys
import os
import subprocess
import re
import tempfile
import importlib.util

# --- Configuration ---
# Delimiters for the labels shown in the UI
L_DELIM = "⠐"
R_DELIM = "⠂"

# --- ANSI Color Definitions ---
COLORS = {
    "reset": "0", "bold": "1", "dim": "2", "underline": "4",
    "red": "31", "green": "32", "blue": "34", "cyan": "36",
    "highlight_orange": "48;5;235;38;5;166", # Solarized dark bg, orange fg
    "highlight_cyan": "48;5;235;38;5;37",   # Solarized dark bg, cyan fg
    "highlight_blue": "48;5;235;38;5;33",   # Solarized dark bg, blue fg
    "dull": "38;5;240",
    "label_color": "1;38;5;46", # Bold bright green
}

def colorize(text, color_name):
    """Wraps text in ANSI color codes."""
    code = COLORS.get(color_name)
    if not code:
        return text
    return f"\033[{code}m{text}\033[0m"

def get_tmux_info(format_string):
    """Runs a tmux display-message command and returns the output."""
    try:
        return subprocess.check_output(
            ["tmux", "display-message", "-p", format_string]
        ).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        return ""

def get_key():
    """Gets a single keypress from the user without requiring Enter."""
    import tty
    import termios
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        char = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return char

def load_rules_from_path(path):
    """Dynamically imports a Python module from a file path."""
    spec = importlib.util.spec_from_file_location("rules", path)
    rules_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(rules_module)
    return rules_module.RULES

def parse_mode(rules_path, pane_path):
    """
    Captures pane content, finds matches, writes temp files,
    and launches the displayer in a tmux popup.
    """
    try:
        rules = load_rules_from_path(rules_path)
    except Exception as e:
        subprocess.run(["tmux", "display-message", f"Error loading rules: {e}"])
        sys.exit(1)

    # Capture pane content, including color formatting
    pane_content = subprocess.check_output(
        ["tmux", "capture-pane", "-p", "-e"]
    ).decode("utf-8")

    label_idx = 0
    matches_data = {}
    annotated_content = []

    for line in pane_content.splitlines():
        all_found_matches = []
        # We search on a color-stripped version of the line to find match positions
        plain_line = re.sub(r'\x1b\[[0-9;]*m', '', line)
        for i, rule in enumerate(rules):
            for match in re.finditer(rule["regex"], plain_line):
                all_found_matches.append({"match": match, "rule_idx": i})
        
        all_found_matches.sort(key=lambda x: x["match"].start())

        new_line = ""
        last_pos = 0
        for found in all_found_matches:
            match = found["match"]
            
            if match.start() < last_pos:
                continue

            if label_idx < 26:
                key = chr(ord('a') + label_idx)
                matches_data[key] = {"text": match.group(0), "rule_idx": found["rule_idx"]}
                # We perform replacements on the plain line
                new_line += plain_line[last_pos:match.start()]
                new_line += f"%%LABEL_{key}%%"
                last_pos = match.end()
                label_idx += 1
            else:
                break
        
        new_line += plain_line[last_pos:]
        annotated_content.append(new_line)

    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as match_file, \
         tempfile.NamedTemporaryFile(mode='w+', delete=False) as content_file:
        
        for key, data in matches_data.items():
            match_file.write(f"{key}:{data['rule_idx']}:{data['text']}\n")
        
        content_file.write("\n".join(annotated_content))
        
        match_filepath = match_file.name
        content_filepath = content_file.name

    pane_w = get_tmux_info("#{pane_width}")
    pane_h = get_tmux_info("#{pane_height}")
    pane_l = get_tmux_info("#{pane_left}")
    pane_t = get_tmux_info("#{pane_top}")
    
    script_path = os.path.abspath(__file__)

    popup_cmd = [
        "tmux", "popup", "-B", "-E",
        "-w", pane_w, "-h", pane_h, "-x", pane_l, "-y", pane_t,
        "--", sys.executable, script_path, "display", rules_path, pane_path, match_filepath, content_filepath
    ]
    subprocess.run(popup_cmd)


def display_mode(rules_path, pane_path, match_filepath, content_filepath):
    """
    Reads annotated files, renders final output, and handles user interaction.
    """
    try:
        rules = load_rules_from_path(rules_path)
    except Exception as e:
        print(f"Error loading rules: {e}")
        sys.exit(1)

    matches = {}
    with open(match_filepath, 'r') as f:
        for line in f:
            key, rule_idx_str, text = line.strip().split(':', 2)
            matches[key] = {"text": text, "rule_idx": int(rule_idx_str)}
    
    with open(content_filepath, 'r') as f:
        annotated_content = f.read()

    # Define raw escape codes for precise control over coloring
    DULL_CODE = f"\033[{COLORS['dull']}m"
    RESET_CODE = f"\033[{COLORS['reset']}m"

    # Process line by line, starting from the cleaned (color-stripped) text
    output_lines = []
    for line in annotated_content.splitlines():
        processed_line = line
        # Replace our placeholders
        for key, data in matches.items():
            if f"%%LABEL_{key}%%" in processed_line:
                rule = rules[data["rule_idx"]]
                label_display = colorize(f"{L_DELIM}{key}{R_DELIM}", "label_color")
                match_display = colorize(data["text"], rule["color"])
                
                # After our colored match (which contains a reset), we must re-apply the dull color.
                replacement = f"{label_display} {match_display}{DULL_CODE}"
                processed_line = processed_line.replace(f"%%LABEL_{key}%%", replacement)
        
        # Start each line with the dull code.
        output_lines.append(f"{DULL_CODE}{processed_line}")

    # Join all processed lines and add a final reset at the very end.
    final_output = "\n".join(output_lines)
    print(f"{final_output}{RESET_CODE}", end="")
    sys.stdout.flush()

    if matches:
        key_pressed = get_key()
        
        if key_pressed in matches:
            data = matches[key_pressed]
            rule = rules[data["rule_idx"]]
            action = rule["action"]
            
            action_type = None
            action_cmd = None

            if callable(action):
                # New lambda-based action: lambda should return (type, command)
                action_type, action_cmd = action(data["text"], pane_path)
            else:
                # Old string-based action for backward compatibility
                action_type, action_cmd_template = action.split(" ", 1)
                action_cmd = action_cmd_template.replace("PLACEHOLDER", data["text"])

            try:
                if action_type == "copy":
                    # Restored original command structure for system clipboard copy
                    copy_cmd = f"tmux set-buffer -w -- '{action_cmd}' && tmux save-buffer - | pbcopy"
                    subprocess.run(copy_cmd, shell=True, check=True)
                    subprocess.run(f"tmux display-message -d 1000 'Copied: {action_cmd}'", shell=True)
                elif action_type == "exec":
                    # The `cd` command is now expected to be part of the action_cmd string itself
                    subprocess.run(action_cmd, shell=True, check=True)
                    subprocess.run(f"tmux display-message -d 1000 'Executed: {action_cmd}'", shell=True)
                elif action_type == "exco":
                    # The `cd` command is now expected to be part of the action_cmd string itself
                    output = subprocess.check_output(action_cmd, shell=True).decode("utf-8").strip()
                    # Restored original command structure for system clipboard copy
                    copy_cmd = f"tmux set-buffer -w -- '{output}' && tmux save-buffer - | pbcopy"
                    subprocess.run(copy_cmd, shell=True, check=True)
                    subprocess.run(f"tmux display-message -d 2000 'Copied: {output}'", shell=True)
                elif action_type == "type":
                    # Send the text directly to the tmux pane
                    subprocess.run(["tmux", "send-keys", action_cmd], check=True)
                    subprocess.run(f"tmux display-message -d 1000 'Typed: {action_cmd}'", shell=True)
                elif action_type == "exty":
                    # Execute command, capture output, and send to tmux pane
                    output = subprocess.check_output(action_cmd, shell=True).decode("utf-8").strip()
                    subprocess.run(["tmux", "send-keys", output], check=True)
                    subprocess.run(f"tmux display-message -d 2000 'Sent: {output}'", shell=True)
            except subprocess.CalledProcessError as e:
                 subprocess.run(
                    f"tmux display-message -d 2000 'Action failed: {e}'",
                    shell=True
                )

    os.remove(match_filepath)
    os.remove(content_filepath)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python tmux-uhm.py <mode> [args...]")
        sys.exit(1)

    mode = sys.argv[1]

    if mode == "parse":
        if len(sys.argv) != 4:
            print("Usage: python tmux-uhm.py parse <rules_path> <pane_path>")
            sys.exit(1)
        rules_path_arg = sys.argv[2]
        pane_path_arg = sys.argv[3]
        parse_mode(rules_path_arg, pane_path_arg)
    elif mode == "display":
        if len(sys.argv) != 6:
            print("Usage: python tmux-uhm.py display <rules_path> <pane_path> <match_file> <content_file>")
            sys.exit(1)
        rules_path_arg = sys.argv[2]
        pane_path_arg = sys.argv[3]
        match_filepath_arg = sys.argv[4]
        content_filepath_arg = sys.argv[5]
        display_mode(rules_path_arg, pane_path_arg, match_filepath_arg, content_filepath_arg)
    else:
        print(f"Unknown mode: {mode}")
        sys.exit(1)
