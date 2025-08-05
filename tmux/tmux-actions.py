#!/usr/bin/env python3
import sys
import subprocess
import re
from pathlib import Path

def find_actions_file(start_path_str):
    """
    Finds the .tmux-actions.md file.
    1. Checks the given starting path.
    2. If not found, checks the root of the git repository, if any.
    Returns a Path object to the file or None if not found.
    """
    start_path = Path(start_path_str)
    
    # 1. Check the current directory first.
    local_file = start_path / ".tmux-actions.md"
    if local_file.exists():
        return local_file

    # 2. If not found, try to find and check the git repository root.
    try:
        # Run git command from the pane's path to find the repo root.
        git_root_proc = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=start_path,
            capture_output=True,
            text=True,
            check=True # Raises an exception if the command fails (e.g., not a git repo)
        )
        git_root = Path(git_root_proc.stdout.strip())
        root_file = git_root / ".tmux-actions.md"
        if root_file.exists():
            return root_file
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        # This occurs if it's not a git repo or git isn't installed.
        # We can safely ignore it and proceed.
        pass

    return None

def display_tmux_message(message):
    """Shows a message in the tmux status line."""
    subprocess.run(["tmux", "display-message", message])

def open_github_repo(repo_path_str):
    """
    Checks if a path is a git repo, gets the remote origin URL,
    parses it, and opens the GitHub page.
    """
    # This function remains unchanged.
    repo_path = Path(repo_path_str)
    git_check = subprocess.run(
        ["git", "-C", str(repo_path), "rev-parse", "--is-inside-work-tree"],
        capture_output=True
    )
    if git_check.returncode != 0:
        display_tmux_message("Not a git repository.")
        return

    git_url_proc = subprocess.run(
        ["git", "-C", str(repo_path), "config", "--get", "remote.origin.url"],
        capture_output=True, text=True
    )
    if git_url_proc.returncode != 0 or not git_url_proc.stdout.strip():
        display_tmux_message("No remote origin found.")
        return

    remote_url = git_url_proc.stdout.strip()
    parsed_url = re.sub(r'.*github\.com[:/]', '', remote_url)
    parsed_url = re.sub(r'\.git$', '', parsed_url)

    if not parsed_url:
        display_tmux_message("Could not parse GitHub URL.")
        return

    final_url = f"https://github.com/{parsed_url}"
    subprocess.run(["open", final_url])


def show_menu(current_path_str):
    """
    Finds or builds a list of actions and displays them in a tmux menu.
    """
    script_path = Path(__file__).resolve()
    current_path = Path(current_path_str) # The original pane path
    
    # Use the new helper function to find the actions file.
    actions_file = find_actions_file(current_path_str)

    menu_items = []
    title = "#[align=centre]Actions…"

    if actions_file:
        content = actions_file.read_text()
        title_match = re.search(r"^#\s+(?!#)(.+)", content, re.MULTILINE)
        if title_match:
            title = f"#[align=centre]{title_match.group(1).strip()}"
        else:
            # Use the name of the directory where the file was found for the title.
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
            
            next_line_idx = i + 1
            while next_line_idx < len(lines) and not lines[next_line_idx].strip():
                next_line_idx += 1

            if next_line_idx < len(lines) and lines[next_line_idx].strip() == "```":
                command_lines = []
                i = next_line_idx + 1
                while i < len(lines) and lines[i].strip() != "```":
                    command_lines.append(lines[i])
                    i += 1
                command = "\n".join(command_lines)
            
            tmux_cmd = ""
            if command is not None:
                # The 'cd' command still uses the original pane path.
                cmd_str = f'cd "{current_path}" ; {command.strip()}'
                tmux_cmd = f"run-shell '{cmd_str}'"
            elif "github" in name.lower():
                cmd_str = f"'{script_path}' --github '{current_path}'"
                tmux_cmd = f"run-shell '{cmd_str}'"
            else:
                i += 1
                continue
            
            menu_items.extend([name, key, tmux_cmd])
            i += 1
    else:
        # Fallback to the default menu if no file is found anywhere.
        default_items = [
            ("VS Code", "c", "code ."),
            ("Open", "o", "open ."),
            ("Github", "g", f"'{script_path}' --github '{current_path}'")
        ]
        for name, key, command in default_items:
            if command.startswith("'"+str(script_path)):
                 cmd_str = command
            else:
                 cmd_str = f'cd "{current_path}" ; {command}'
            tmux_cmd = f"run-shell '{cmd_str}'"
            menu_items.extend([name, key, tmux_cmd])

    if menu_items:
        menu_items.append("")
    menu_items.extend(["Exit", "q", ""])
    subprocess.run(["tmux", "display-menu", "-T", title, "-x", "C", "-y", "C"] + menu_items)


def main():
    """Main router: decides whether to show the menu or open GitHub."""
    # This function remains unchanged.
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