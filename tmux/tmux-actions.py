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
            h2_match = re.match(r"^##\s*\[`(.+?)`\]\s*(.+?)$", line)
            if not h2_match:
                i += 1
                continue

            key, name = [g.strip() for g in h2_match.groups()]
            command = None
            
            # Find start of the code block
            next_line_idx = i + 1
            while next_line_idx < len(lines) and not lines[next_line_idx].strip():
                next_line_idx += 1

            if next_line_idx < len(lines) and lines[next_line_idx].strip().startswith("```"):
                command_lines = []
                # Check for special github command
                if "github" in lines[next_line_idx].strip():
                     command = "github"
                else:
                    i = next_line_idx + 1
                    while i < len(lines) and lines[i].strip() != "```":
                        command_lines.append(lines[i])
                        i += 1
                    command = "\n".join(command_lines).strip()
            
            tmux_cmd = ""
            if command == "github":
                cmd_str = f"'{script_path}' --github '{current_path}'"
                tmux_cmd = f"run-shell '{cmd_str}'"
            elif command:
                cmd_str = f'cd "{current_path}" && {command}'
                tmux_cmd = f"run-shell '{cmd_str}'"
            else: # No command block found, move to the next line
                 i+=1
                 continue

            menu_items.extend([name, key, tmux_cmd])
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