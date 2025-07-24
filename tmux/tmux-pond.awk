#!/usr/bin/awk -f

# This script simulates ripples on a digital pond.
# Handles Ctrl+C gracefully for a clean exit.

BEGIN {
    # --- Configuration ---
    max_ripples = 5
    new_ripple_prob = 0.04 # Chance to create a new ripple each frame
    concentric_rings = 8   # Number of rings per ripple

    # --- Initialization ---
    srand()
    "tput cols" | getline width
    "tput lines" | getline height
    close("tput cols")
    close("tput lines")

    # Define a palette of subtle water colors (256-color codes)
    color_list = "24 25 26 27 31 32 33" # Blues
    num_colors = split(color_list, colors, " ")

    # Hide cursor and clear screen
    printf "\033[?25l\033[2J"

    num_active_ripples = 0

    # --- Main Animation Loop ---
    while (1) {
        # Randomly create a new ripple
        if (rand() < new_ripple_prob && num_active_ripples < max_ripples) {
            num_active_ripples++
            ripple_x[num_active_ripples] = int(rand() * width) + 1
            ripple_y[num_active_ripples] = int(rand() * height) + 1
            ripple_r[num_active_ripples] = 1 # Initial radius
            ripple_color[num_active_ripples] = colors[int(rand() * num_colors) + 1]
        }

        # Animate and draw all active ripples
        for (i = 1; i <= num_active_ripples; i++) {
            # Erase the tail of the wave (the oldest ring)
            draw_circle(ripple_x[i], ripple_y[i], ripple_r[i] - concentric_rings, " ")

            # Draw the new set of concentric rings
            for (k = 0; k < concentric_rings; k++) {
                current_radius = ripple_r[i] - k
                if (current_radius <= 0) continue

                # Outermost ring is brightest and has a different character
                if (k == 0) {
                    char = (ripple_r[i] % 4 < 2) ? "o" : "."
                    draw_circle(ripple_x[i], ripple_y[i], current_radius, char, ripple_color[i], 1)
                } else {
                    # Inner rings are dimmer and are always dots
                    draw_circle(ripple_x[i], ripple_y[i], current_radius, ".", ripple_color[i], 0)
                }
            }

            # Grow the ripple
            ripple_r[i]++

            # Mark ripple for deletion if it's too big
            if (ripple_r[i] > width / 2) {
                # Erase the full ripple before deleting
                for (k = 0; k < concentric_rings; k++) {
                   draw_circle(ripple_x[i], ripple_y[i], ripple_r[i] - 1 - k, " ")
                }
                ripple_r[i] = -1 # Mark as dead
            }
        }
        fflush()

        # Clean up dead ripples from the array
        j = 1
        for (i = 1; i <= num_active_ripples; i++) {
            if (ripple_r[i] != -1) {
                ripple_x[j] = ripple_x[i]
                ripple_y[j] = ripple_y[i]
                ripple_r[j] = ripple_r[i]
                ripple_color[j] = ripple_color[i]
                j++
            }
        }
        num_active_ripples = j - 1

        # Pause and check for interrupt
        if (system("sleep 0.04") != 0) {
            system("clear")
            printf "\033[2J\033[?25h\033[0m"
            exit
        }
    }
}

# Function to draw a circle of characters at a given radius
function draw_circle(cx, cy, r, char, color, brightness,   i,theta,x,y,steps) {
    if (r <= 0) return
    if (brightness == "") brightness = "0" # Default to normal brightness

    steps = int(2 * 3.14159 * r) # Number of points on circumference
    if (steps < 8) steps = 8

    for (i = 0; i < steps; i++) {
        theta = (2 * 3.14159 / steps) * i
        x = int(cx + r * cos(theta))
        y = int(cy + r * sin(theta) * 0.5) # Multiply by 0.5 to correct for non-square character aspect ratio

        if (x >= 1 && x <= width && y >= 1 && y <= height) {
            if (color) {
                printf "\033[%d;%dH\033[%s;38;5;%dm%s\033[0m", y, x, brightness, color, char
            } else {
                printf "\033[%d;%dH%s", y, x, char
            }
        }
    }
}

END {
    # Restore cursor and clear screen on exit
    printf "\033[2J\033[?25h\033[0m"
}
