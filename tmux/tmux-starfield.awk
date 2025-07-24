#!/usr/bin/awk -f

# This script creates a 3D starfield effect, simulating flight through space.
# It handles Ctrl+C gracefully for a clean exit.

BEGIN {
    # --- Configuration ---
    num_stars = 400
    speed = 0.005 # Slower speed

    # --- Initialization ---
    srand()
    "tput cols" | getline width
    "tput lines" | getline height
    close("tput cols")
    close("tput lines")

    center_x = width / 2
    center_y = height / 2

    # Define a palette of subtle star colors (256-color codes)
    color_list = "252 229 153 250" # Dim whites, pale yellow, pale blue
    num_colors = split(color_list, colors, " ")

    # Hide cursor and clear screen
    printf "\033[?25l\033[2J"

    # Initialize stars with random 3D positions and a persistent color
    for (i = 1; i <= num_stars; i++) {
        # x and y are between -1 and 1
        star_x[i] = (rand() * 2) - 1
        star_y[i] = (rand() * 2) - 1
        # z is the depth, from a small value up to 1
        star_z[i] = rand()
        # Assign a random color from the palette to each star
        star_color[i] = colors[int(rand() * num_colors) + 1]
    }

    # --- Main Animation Loop ---
    while (1) {
        # Clear the screen for the next frame
        printf "\033[2J"

        for (i = 1; i <= num_stars; i++) {
            # Move star closer to the viewer
            star_z[i] -= speed

            # If star is behind the viewer, reset it to the back
            if (star_z[i] <= 0) {
                star_x[i] = (rand() * 2) - 1
                star_y[i] = (rand() * 2) - 1
                star_z[i] = 1
            }

            # Project 3D coordinates to 2D screen
            # The division by z creates the perspective effect
            px = center_x + (star_x[i] / star_z[i]) * center_x
            py = center_y + (star_y[i] / star_z[i]) * center_y

            # Determine character and brightness based on distance (z)
            char = "."
            brightness = "0" # Normal brightness

            if (star_z[i] < 0.7) { char = "o"; brightness = "1" } # Brighter
            if (star_z[i] < 0.4) { char = "O"; }
            if (star_z[i] < 0.2) { char = "*"; }

            # Draw the star if it's within the screen bounds
            if (px >= 1 && px <= width && py >= 1 && py <= height) {
                # Use the star's assigned color, adjusted for brightness
                printf "\033[%d;%dH\033[%s;38;5;%dm%s\033[0m", py, px, brightness, star_color[i], char
            }
        }
        fflush()

        if (system("sleep 0.01") != 0) {
            system("clear")
            printf "\033[2J\033[?25h\033[0m"
            exit
        }
    }
}

END {
    # Restore cursor and clear screen on exit
    printf "\033[2J\033[?25h\033[0m"
}
