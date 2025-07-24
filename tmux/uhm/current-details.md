# Tmux Universal Hint Manager (UHM)

WIP.

Note (RB): I used "uhm" as placeholder name (uuuhmm I have no idea yet), and Gemini made up this
name when I asked for notes and description. It's actually pretty good as a name, so I'll keep it.

Inspired by https://github.com/morantron/tmux-fingers (which is actually a polished thing and not
a 30 minutes hack with an LLM).

## 1. Overview

This is a two-script `awk` system designed to run within `tmux`. It allows a user to press a
keybinding, which highlights all occurrences of a predefined regular expression (currently file
paths) on the visible part of their active pane. Each match is given a lettered label. The user can
then press a corresponding letter to trigger an action with the content of that match.

## 2. Workflow

1.  **Trigger**: The user presses a `tmux` keybinding (`Prefix + H`). This executes the primary script (`tmux-uhm-process.awk`).

2.  **Processing & Launch (`tmux-uhm-process.awk`)**:

    - The script captures **only the visible text** of the current `tmux` pane to a temporary file, ignoring scrollback history.
    - It reads this captured text and finds all strings that match a hardcoded regex (`/Users/ruben/[a-zA-Z0-9_./-]+`).
    - It generates two new temporary files:
      - A **match file** containing `key:value` pairs for each match (e.g., `a:/Users/ruben/file.txt`). Labels go from `a` to `z`.
      - An **annotated content file** where each match in the original text is replaced by a simple marker (e.g., `%%LABEL_a%%`).
    - Finally, it launches a full-screen `tmux` popup, telling it to run the second script.

3.  **Display & Interaction (`tmux-uhm-display.awk`)**:

    - This script runs inside the popup.
    - It first reads the **match file** to load the `a -> /path/..` mappings into memory.
    - It then reads the **annotated content file** line-by-line. For each line, it replaces the markers (`%%LABEL_a%%`, etc.) with fully styled text, which includes:
      - Dulling all non-matched text to a gray color.
      - Adding a colored label (e.g., `[a]`).
      - Highlighting the corresponding path text.
    - The fully rendered text is printed to the popup window.
    - After all text is displayed, it prints an interactive prompt.

4.  **Action**:
    - The script waits for a **single keypress** from the user (without needing `Enter`), using a robust `stty` and `dd` method.
    - If the key pressed matches a label ('a', 'b', etc.), the script executes `tmux display-message` to briefly flash the full path associated with that label in the `tmux` status line.
    - The popup closes after the key is pressed and the action is performed.

## 3. Cleanup

All temporary files created during the process are automatically deleted upon completion.
