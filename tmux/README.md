# My Tmux Scripts

This repository is a collection of custom `AWK` and `Python` scripts designed to enhance the `tmux` terminal multiplexer experience. They range from a dynamic menu system to aesthetic animations and command-line utilities.

---

## Scripts

### `tmux-actions.py`

This Python script provides a powerful, context-aware menu system for `tmux`. It works by first looking for a `.tmux-actions.md` file in the current pane's directory. If a file isn't found there, it searches for one in the root of the current Git repository (if any). This allows for a single, project-wide actions file. The script uses this file to build a pop-up menu of commands. A special `## [...] … github …` entry with no code block will automatically create an action to open the repository's GitHub page. If no configuration file is found in either location, it presents a default menu.

[Here you can see a example configuration "live"](https://github.com/rberenguel/obsidian-escoli-plugin/blob/main/.tmux-actions.md).

#### Action Formatting

Actions are defined using Markdown H2 headers. The format is `## [<key>] <Description>`.

-   **`<key>`**: A single character to trigger the action.
-   **`<Description>`**: The text that appears in the menu.

The command to be executed is placed in a fenced code block on the following lines.

```markdown
## [`c`] Open VS Code

```code
.
```
```

#### Execution Modifiers

The behavior of the command execution can be modified by adding a prefix to the key in the header:

-   **No prefix (e.g., `c`)**: This is the default. The command is executed in the background, and its output is hidden (`run-shell -b -C`). This is useful for commands that don't need user interaction or visual confirmation, like opening an application.
-   **`.` prefix (e.g., `.b`)**: The command is executed in the background, but its output is shown in a new tmux window (`run-shell -b`). This is useful for build scripts or other commands where you want to see the output.
-   **`!` prefix (e.g., `!s`)**: The command is sent to the current tmux pane and executed as if you typed it yourself (i.e., in the foreground, using `send-keys`). This is for interactive commands or scripts that need to run in the current shell.

#### Dynamic Menu Items

The description can be dynamic by enclosing a command in backticks. The script will execute this command and replace the description with its standard output.

```markdown
## [`d`] `Dynamic: Show Date`

```
date
```
```

In this example, the menu will display the current date and time. When selected, it will run `date` again. The execution modifier (`.` or `!`) applies to the command in the code block, not the command used to generate the dynamic title. For dynamic titles that are purely informational, it's common to have the associated action be the same command running silently (the default behavior).

---

### Aesthetic Animations

These are "screensaver" style scripts written in `AWK` that provide visual effects. They handle terminal resizing and exit gracefully on `Ctrl+C`.

#### `tmux-starfield.awk`

This script creates a 3D starfield effect, simulating flight through space. It initializes a set number of stars with random 3D positions and moves them closer to the viewer in a loop. The character used for the star changes based on its proximity, creating a sense of depth.

#### `tmux-matrix.awk`

This script produces the classic "digital rain" effect inspired by *The Matrix*. It uses a space-separated list of Katakana characters for the rain and a palette of green shades for the trail. There is also a very small chance for a character to appear in red for contrast.

#### `tmux-pond.awk`

This script simulates raindrops creating concentric, expanding ripples on a digital pond. It randomly creates new ripples, each consisting of several concentric rings. The outermost ring of a ripple has a different character to represent the wave's leading edge.

#### `tmux-mondrian.awk`

This script generates random geometric art inspired by Piet Mondrian, creating a new "painting" every 10 seconds. It works by recursively partitioning the screen area, drawing black dividing lines between the sections. Final rectangles have a 35% chance to be filled with a primary color from a dark mode palette; otherwise, they are filled with a background grey.

---

### Utility Scripts

#### `tmux-slow-type.awk`

This script simulates human-like typing directly into a `tmux` pane. It can be configured with variables for typing delay and mistake rate. When a mistake is simulated, it types a wrong character, pauses, sends a backspace, pauses again, and then sends the correct character.

#### `tmux-notify.awk`

A utility script to display formatted success (`✓`) or failure (`✗`) notifications in the `tmux` status line. The background color, foreground color, icon, and message are determined by the exit `status` (0 for success) passed to the script. It is designed to be called after a command completes to provide visual feedback.