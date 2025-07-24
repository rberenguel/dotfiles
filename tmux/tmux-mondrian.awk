#!/usr/bin/awk -f

# This script generates random geometric art inspired by Piet Mondrian.
# A new "painting" is created every 10 seconds.
# Handles Ctrl+C gracefully for a clean exit.

BEGIN {
    # --- Initialization ---
    srand()
    "tput cols" | getline width
    "tput lines" | getline height
    close("tput cols")
    close("tput lines")

    # --- Configuration ---
    # Dark Mode Mondrian palette (256-color codes): Dark Red, Dark Yellow, Dark Blue
    split("88 130 20", colors, " ")
    num_colors = 3
    black = 16
    background_color = 250 # A lighter dark grey for the "white" space, 237-255 are grey/white
    line_width = 1 # Width of the black dividing lines

    # Hide cursor
    printf "\033[?25l"

    # --- Main Loop ---
    while (1) {
        printf "\033[2J" # Clear screen

        # Start the recursive partitioning from the full screen, starting at depth 0
        split_area(1, 1, width, height, 0)
        fflush()

        if (system("sleep 10") != 0) {
            system("clear")
            printf "\033[2J\033[?25h\033[0m"
            exit
        }
    }
}

# Recursively splits an area into smaller rectangles
function split_area(x, y, w, h, depth,  split_pos, split_dir) {
    # Stop splitting if the area is too small or by random chance after a few splits.
    min_dim = 20 # Increased minimum dimension for larger rectangles
    # We only introduce the random chance to stop splitting after depth 2.
    if (w < min_dim || h < min_dim || (depth >= 2 && rand() < 0.3)) {
        # When a rectangle is final, fill it with a color or the background grey
        if (rand() < 0.35) { # 35% chance to be colored
            color_idx = int(rand() * num_colors) + 1
            fill_rect(x, y, w, h, colors[color_idx])
        } else { # Fill the rest with the dark background color
            fill_rect(x, y, w, h, background_color)
        }
        return
    }

    # Decide to split vertically or horizontally based on the rectangle's shape
    if (w > h) {
        split_dir = "v" # Vertical split is more natural for wide rectangles
    } else if (h > w) {
        split_dir = "h" # Horizontal split for tall ones
    } else {
        split_dir = (rand() < 0.5) ? "v" : "h" # Split squares randomly
    }

    if (split_dir == "v") {
        # Perform a vertical split
        split_pos = x + int(w * (0.3 + rand() * 0.4)) # Find a split point near the middle
        split_area(x, y, split_pos - x, h, depth + 1)
        split_area(split_pos + line_width, y, w - (split_pos - x) - line_width, h, depth + 1)
        fill_rect(split_pos, y, line_width, h, black) # Draw the dividing line
    } else {
        # Perform a horizontal split
        split_pos = y + int(h * (0.3 + rand() * 0.4))
        split_area(x, y, w, split_pos - y, depth + 1)
        split_area(x, split_pos + line_width, w, h - (split_pos - y) - line_width, depth + 1)
        fill_rect(x, split_pos, w, line_width, black) # Draw the dividing line
    }
}

# Fills a rectangle with a solid background color
function fill_rect(start_x, start_y, w, h, color_code,   x, y) {
    # Set background color using ANSI escape codes
    printf "\033[48;5;%dm", color_code

    # Draw the rectangle line by line
    for (y = start_y; y < start_y + h; y++) {
        printf "\033[%d;%dH", y, start_x # Move cursor to position
        for (x = 0; x < w; x++) {
            printf " "
        }
    }
    printf "\033[0m" # Reset all attributes
}

END {
    # Restore cursor on exit
    printf "\033[?25h\033[0m"
}
