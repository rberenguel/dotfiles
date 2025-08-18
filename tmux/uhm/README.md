# My Tmux Scripts

This repository is a collection of custom `AWK` and `Python` scripts designed to enhance the `tmux` terminal multiplexer experience. They range from a dynamic menu system to aesthetic animations and command-line utilities.

---

## Scripts

### `tmux-uhm.py`

This Python script provides a context-aware utility for interacting with highlighted text in your tmux pane. It captures the pane content, identifies text matching predefined regular expressions (defined in `rules.py`), and presents them in a popup. When a matched item is selected, it performs a specified action.

Supported actions include:

-   **`copy`**: Copies the matched text or the output of a command to the system clipboard.
-   **`exec`**: Executes a command directly in the shell.
-   **`exco`**: Executes a command, captures its output, and copies that output to the system clipboard.
-   **`type`**: Sends the matched text directly to the current tmux pane as if typed, without a newline.
-   **`exty`**: Executes a command, captures its output, and sends that output to the current tmux pane as if typed, without a newline.
