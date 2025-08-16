#!/usr/bin/env python3
import sys
import subprocess
import re
from pathlib import Path

def find_actions_file(start_path_str):
    """
    Finds the actions file.
    1. Checks for .tmux-actions.md in the starting path.
    2. Checks for .tmux-actions.md in the git repository root.
    3. Falls back to tmux-actions.default.md in the script's directory.
    Returns a Path object to the file or None if not found.
    """
    start_path = Path(start_path_str)
    script_dir = Path(__file__).parent.resolve()

    # 1. Check the current directory first.
    local_file = start_path / ".tmux-actions.md"
    if local_file.exists():
        return local_file

    # 2. If not found, try to find and check the git repository root.
    try:
        git_root_proc = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=start_path,
            capture_output=True,
            text=True,
            check=True
        )
        git_root = Path(git_root_proc.stdout.strip())
        root_file = git_root / ".tmux-actions.md"
        if root_file.exists():
            return root_file
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    # 3. Fallback to the default file in the script's directory.
    default_file = script_dir / "tmux-actions.default.md"
    if default_file.exists():
        return default_file

    return None

def display_tmux_message(message):
    """Shows a message in the tmux status line."""
    subprocess.run(["tmux", "display-message", message])

def open_github_repo(repo_path_str):
    """
    Checks if a path is a git repo, gets the remote origin URL,
    parses it, and opens the GitHub page.
    """
    repo_path = Path(repo_path_str)
    try:
        git_url_proc = subprocess.run(
            ["git", "-C", str(repo_path), "config", "--get", "remote.origin.url"],
            capture_output=True, text=True, check=True
        )
        remote_url = git_url_proc.stdout.strip()
        parsed_url = re.sub(r'.*github\.com[:/]', '', remote_url)
        parsed_url = re.sub(r'\.git$', '', parsed_url)
        if parsed_url:
            final_url = f"https://github.com/{parsed_url}"
            subprocess.run(["open", final_url])
        else:
            display_tmux_message("Could not parse GitHub URL.")
    except (subprocess.CalledProcessError, FileNotFoundError):
        display_tmux_message("Not a git repository or no remote origin found.")

def show_menu(current_path_str):
    """
    Finds or builds a list of actions and displays them in a tmux menu.
    """
    script_path = Path(__file__).resolve()
    current_path = Path(current_path_str)
    
    actions_file = find_actions_file(current_path_str)

    menu_items = []
    title = "#[align=centre]Actions…"

    if actions_file:
        content = actions_file.read_text()
        title_match = re.search(r"^#\s+(?!#)(.+)", content, re.MULTILINE)
        if title_match:
            title = f"#[align=centre]{title_match.group(1).strip()}"
        else:
            title = f"#[align=centre]{actions_file.parent.name} Actions…"

        lines = content.splitlines()
        i = 0
        while i < len(lines):
            line = lines[i]

            # ADDED: Check for a separator line
            if line.strip() == '---':
                menu_items.append("")
                i += 1
                continue

            h2_match = re.match(r"^##\s*(?:\[`(.+?)`\]\s*)?(.+?)$", line)
            if not h2_match:
                i += 1
                continue

            groups = h2_match.groups()
            key_raw = groups[0].strip() if groups[0] else "" 
            name_placeholder = groups[1].strip()

            send_keys_mode = key_raw.startswith('!')
            key = key_raw[1:] if send_keys_mode else key_raw

            is_dynamic_name = name_placeholder.startswith('`') and name_placeholder.endswith('`')
            
            command = None
            press_enter = None

            next_line_idx = i + 1
            while next_line_idx < len(lines) and not lines[next_line_idx].strip():
                next_line_idx += 1

            if next_line_idx < len(lines):
                command_line = lines[next_line_idx]
                stripped_command_line = command_line.strip()

                blockquote_match = re.match(r">\s*`([^`]+)`\s*$", stripped_command_line)

                if blockquote_match:
                    press_enter = False
                    command = blockquote_match.group(1)
                    i = next_line_idx
                elif stripped_command_line.startswith("```"):
                    press_enter = True
                    if "github" in stripped_command_line:
                        command = "github"
                    else:
                        command_lines = []
                        i = next_line_idx + 1
                        while i < len(lines) and lines[i].strip() != "```":
                            command_lines.append(lines[i])
                            i += 1
                        command = "\n".join(command_lines).strip()

            if command is None and 'github' in name_placeholder.lower():
                command = 'github'

            if not command:
                i += 1
                continue

            final_name = name_placeholder
            if is_dynamic_name and command != "github":
                try:
                    proc = subprocess.run(
                        command,
                        shell=True,
                        cwd=current_path,
                        capture_output=True,
                        text=True,
                        check=True,
                        timeout=5
                    )
                    final_name = proc.stdout.strip()
                except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                    error_message = e.stderr.strip() if hasattr(e, 'stderr') and e.stderr else str(e)
                    final_name = f"ERR: {error_message}"
            
            if send_keys_mode:
                final_name = f"! {final_name}"

            tmux_cmd = ""
            if command == "github":
                cmd_str = f"'{script_path}' --github '{current_path}'"
                tmux_cmd = f"run-shell -b '{cmd_str}'"
            else:
                cmd_str = command.replace("'", "'\\''")
                full_command = f'cd "{current_path}" && {cmd_str}'
                if press_enter:
                    if send_keys_mode:
                        # Send keys to the current pane for execution.
                        tmux_cmd = f"send-keys -t . '{full_command}' C-m"
                    else:
                        # Execute in the background for non-blocking commands.
                        tmux_cmd = f"run-shell -b '{full_command}'"
                else:
                    # Just type the command in the current pane without executing.
                    tmux_cmd = f"send-keys -t . '{full_command}'"

            menu_items.extend([f"{final_name}", key, tmux_cmd])
            i += 1
    else:
        display_tmux_message("No actions file found.")

    if menu_items:
        menu_items.append("")
    menu_items.extend(["Exit", "q", ""])
    subprocess.run(["tmux", "display-menu", "-T", title, "-x", "C", "-y", "C"] + menu_items)

def main():
    """Main router: decides whether to show the menu or open GitHub."""
    if "--github" in sys.argv:
        try:
            repo_path = sys.argv[sys.argv.index("--github") + 1]
            open_github_repo(repo_path)
        except IndexError:
            display_tmux_message("Error: --github flag requires a path.")
    else:
        if len(sys.argv) < 2:
            display_tmux_message("Error: script requires a path argument.")
            return
        show_menu(sys.argv[1])

if __name__ == "__main__":
    main()