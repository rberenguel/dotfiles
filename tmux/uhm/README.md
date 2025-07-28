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
* Copies the selected match to the system clipboard.
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
    bind-key u run-shell "env UHMPATH=/Users/ruben/code/dotfiles/tmux/uhm /opt/homebrew/bin/gawk -f /Users/ruben/code/dotfiles/tmux/uhm/rules.awk -f /Users/ruben/code/dotfiles/tmux/uhm/tmux-uhm.awk -v mode=parse -- /Users/ruben/code/dotfiles/tmux/uhm/rules.awk"
    ```
    Reload your `tmux` configuration for the binding to take effect (`tmux source-file ~/.tmux.conf`).

We provide it with a path to where the script lives in `UHMPATH` (_doompety doo_), the full `gawk` binary path (it will be used by the script) and 
pass the rules twice. The script calls itself, and needs the rules to import on the second call.

## Configuration

All configuration is done in the `rules.awk` file. You define a "triplet" of arrays for each rule you want to add.

Context is not used for now, but the idea is that it will be used as a hint to know what to highlight and what not.

```awk
# ~/.config/tmux/uhm/rules.awk

BEGIN {
    _regex_count = 0

    # --- Your Rules ---

    # Rule 1: Git full hash
    _regex_count++
    REGEXES[_regex_count]     = "[a-f0-9]{40}"
    CONTEXTS[_regex_count]    = "Git Commit"  # Optional context for future use
    RULE_COLORS[_regex_count] = "highlight_orange"

    # Rule 2: Paths in your code folder
    _regex_count++
    REGEXES[_regex_count]     = "/Users/ruben/code/[a-zA-Z0-9_./-]+"
    CONTEXTS[_regex_count]    = "Local Path"
    RULE_COLORS[_regex_count] = "highlight_cyan"

    # Add more rules here...
}