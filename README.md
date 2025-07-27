# dotfiles

## Git

I specially love `nuke`

## Tmux

This setup provides several quality-of-life improvements without external plugins.

### Main Features

- **Prefix**: Remapped to `Ctrl+p`
- **Navigation**: Colemak-friendly pane navigation (`n, o, i, e` for left, right, up, down without moving the right hand fingers).
- **Mouse Support**: Enabled by default (`prefix + m` to toggle). Selecting text copies to the system clipboard.
- **Auto-naming**: Windows are automatically renamed to the name of the git repository they are in, but can be renamed manually.
- **Path Awareness**: New panes and windows open in the current working directory.

#### UHM

See the `tmux/uhm` folder for details on the _Universal Hint Manager_.

### Status Bar

The status bar is styled with a Dracula-ish theme and provides the following information:

- **Left**: Current session name.
- **Center**: A list of windows, with the current window's name derived from its git repository.
- **Right**:
    - The current git repository and branch.
    - A mouse indicator (`🐭`) when mouse support is active.
    - The current time in Zurich and the date.

### Keybindings & Menus

- `prefix + |` or `-`: Split pane horizontally or vertically.
- `prefix + t`: Open a large popup terminal (`75%` of the screen), handy for running transient commands in the current path while another process is running in the foreground.
- `prefix + d`: Display a menu to quickly edit dotfiles (`.zshrc`, `.tmux.conf`).
- `prefix + C-o`: Display a context menu with actions:
    - Open the current directory in VS Code.
    - Open the corresponding GitHub repository in the browser.
- `prefix + g`: A shortcut to directly open the project's GitHub page.

### "Screensavers"

Why not.

### Alternate text insertion table

The binding `prefix + Ctrl+t` switches to an alternate key table, for "fake typing". Currently has the following:

- **Notifications**: You can easily get a success/failure notification for any command. After typing a long-running command, press `prefix + Ctrl+t` then `n` to automatically append a call to the `tmux-notify.awk` script. It will show a `✓ ok` or `✗ nok` message upon completion.
  - `some-long-command.sh ; notif $? "ok" "nok"`
- **Live Demos**: A "fake typing" mode can be triggered with `prefix + Ctrl+t`. Once in this mode, you can configure several keybindings to introduce text, which will be type out with human-like delays and mistakes. Handy for live demos. There is a `lorem ipsum` example

### Helper Scripts

The configuration is enhanced by a few small, standalone `awk` scripts:

- **`tmux-notify.awk`**: Displays a formatted success (`✓`) or failure (`✗`) message in the status bar. This can be hooked into long-running commands to provide a clear in other panes/windows.
- **`tmux-open-gh.awk`**: A robust script that opens the GitHub page for any given repository path. It correctly parses SSH and HTTPS URLs.
- **`tmux-slow-type.awk`**: A script to simulate human typing. It introduces variable delays and a configurable mistake rate to look more natural.
- **`tmux-mondrian/starfield/pond/matrix`**: "Screensavers" created by Gemini. May or may not work in your setup. The matrix one is very good.

These live on my home folder as symlinks pointing to this repo.
