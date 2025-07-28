# Tmux Universal Hint Manager (UHM)

A `tmux` utility for finding and copying based on regex matches in any pane.

![](https://raw.githubusercontent.com/rberenguel/dotfiles/refs/heads/main/tmux/uhm/uhm.png)

---

> [!NOTE]
> I used "uhm" as placeholder name (uuuhmm I have no idea yet), and Gemini made up this
> name when I asked for notes and description. It's actually pretty good as a name, so I'll keep it.

Inspired by https://github.com/morantron/tmux-fingers (which is actually a polished thing and not
a 60 minutes hack with an LLM).

> [!WARNING]
> Gemini is not great with awk.

## Description

`uhm` scans the visible text in your current `tmux` pane for patterns you define (like file paths, git hashes, URLs, etc.). It then presents an interactive popup overlay, assigning a letter to each match. Pressing a letter copies the corresponding match to your system clipboard (currently only on Mac).

This provides a fast, keyboard-driven way to grab important text without leaving your terminal or using the mouse.

## Features

* Finds regex matches in the visible `tmux` pane.
* Configurable via a simple `rules.awk` file.
* Interactive popup for selecting matches.
* Copies the selected match to the system clipboard, executes a command, or copies the output of a command.
* Works correctly with split panes, creating a properly sized overlay.

## Installation & Setup

1.  **Dependencies:** Ensure you have `tmux` and `gawk` (GNU Awk) installed.

2.  **File Structure:** Place the script files in a dedicated directory. A good location is `~/.config/tmux/uhm/`. You can place your rules anywhere though.

    ```
    ~/.config/tmux/uhm/
    ├── tmux-uhm.awk
    └── rules.awk
    ```

3.  **Tmux Binding:** Add a key binding to your `~/.tmux.conf` file to launch the script.

    ```tmux
    # In ~/.tmux.conf
    # This sets up copying even in remote hosts
    set -s set-clipboard on
    set -as terminal-features ',rxvt-unicode-256color:clipboard'
    # Pressing Prefix + u will run the script.
    bind-key u run-shell "env UHMPATH=/Users/ruben/code/dotfiles/tmux/uhm gawk -f /Users/ruben/code/dotfiles/tmux/uhm/rules.awk -f /Users/ruben/code/dotfiles/tmux/uhm/tmux-uhm.awk -v mode=parse -- /Users/ruben/code/dotfiles/tmux/uhm/rules.awk #{pane_current_path}"
    ```
    Reload your `tmux` configuration for the binding to take effect (`tmux source-file ~/.tmux.conf`).

We provide it with a path to where the script lives in `UHMPATH` (_doompety doo_), the full `gawk` binary path (it will be used by the script) and 
pass the rules twice. The script calls itself, and needs the rules to import on the second call.

## Configuration

All configuration is done in the `rules.awk` file. You define a "quadruplet" of arrays for each rule you want to add: `REGEXES`, `CONTEXTS`, `RULE_COLORS`, and `ACTIONS`.

*   `REGEXES`: The regular expression to match.
*   `CONTEXTS`: (Optional) A context string for future use.
*   `RULE_COLORS`: The color to highlight the match in the popup.
*   `ACTIONS`: The action to perform when a match is selected. This can be one of three types:
    *   `copy <template>`: Copies the `<template>` to the clipboard. `PLACEHOLDER` in the template will be replaced by the matched text.
    *   `exec <command>`: Executes the `<command>`. `PLACEHOLDER` in the command will be replaced by the matched text.
    *   `exco <command>`: Executes the `<command>`, captures its output, and copies the output to the clipboard. `PLACEHOLDER` in the command will be replaced by the matched text. `PANE_PATH` will be replaced by the current pane's path.

```awk
# ~/.config/tmux/uhm/rules.awk

BEGIN {
    _regex_count = 0

    # --- Your Rules ---

    # Rule 1: Git full hash
    _regex_count++
    REGEXES[_regex_count]     = "[a-f0-9]{40}"
    CONTEXTS[_regex_count]    = ""
    RULE_COLORS[_regex_count] = "highlight_orange"
    ACTIONS[_regex_count] = "exco open https://github.com/$(cd PANE_PATH; gh repo view --json nameWithOwner -q .nameWithOwner | /bin/cat)/commit/PLACEHOLDER"

    # Rule 2: Paths in your code folder
    _regex_count++
    REGEXES[_regex_count]     = "/Users/ruben/code/[a-zA-Z0-9_./-]+"
    CONTEXTS[_regex_count]    = ""
    RULE_COLORS[_regex_count] = "highlight_cyan"
    ACTIONS[_regex_count] = "exec open PLACEHOLDER"

    # Add more rules here...
}