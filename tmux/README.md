# My Tmux Scripts

This repository is a collection of custom `AWK` and `Python` scripts designed to enhance the `tmux` terminal multiplexer experience. They range from a dynamic menu system to aesthetic animations and command-line utilities.

---

## Scripts

### `tmux-actions.py`

This Python script provides a powerful, context-aware menu system for `tmux`. It works by first looking for a `.tmux-actions.md` file in the current pane's directory. If a file isn't found there, it searches for one in the root of the current Git repository (if any). This allows for a single, project-wide actions file. The script uses this file to build a pop-up menu of commands. A special `## [...] … github …` entry with no code block will automatically create an action to open the repository's GitHub page. If no configuration file is found in either location, it presents a default menu.

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