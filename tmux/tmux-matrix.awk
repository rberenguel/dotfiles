#!/usr/bin/awk -f

BEGIN {
    # --- Configuration ---
    # Characters used for the rain. Katakana is classic.
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    # To handle multi-byte characters robustly, we define them as a space-separated list.
    chars_katakana = "ア ァ カ サ タ ナ ハ マ ヤ ャ ラ ワ ガ ザ ダ バ パ イ ィ キ シ チ ニ ヒ ミ リ ヰ ギ ジ ヂ ビ ピ ウ ゥ ク ス ツ ヌ フ ム ユ ュ ル グ ズ ブ ヅ プ エ ェ ケ セ テ ネ ヘ メ レ ヱ ゲ ゼ デ ベ ペ オ ォ コ ソ ト ノ ホ モ ヨ ョ ロ ヲ ゴ ゾ ド ボ ポ ヴ ッ ン"

    # --- Initialization ---
    srand()
    # Get terminal dimensions portably using tput
    "tput cols" | getline width
    "tput lines" | getline height
    close("tput cols")
    close("tput lines")

    # Define a range of green shades (256-color codes) for the trail
    green_shades = "22 28 34 40 46"
    num_shades = split(green_shades, green_array, " ")
    red_code = 196 # A bright red for contrast
    num_chars = split(chars_katakana, char_array, " ")

    # Hide cursor and clear screen
    printf "\033[?25l\033[2J"

    # Initialize drops, one for each column
    for (i = 1; i <= width; i++) {
        drops[i] = -int(rand() * height) # Start off-screen
        speeds[i] = int(rand() * 3) + 1 # Random speed
    }

    # --- Main Animation Loop ---
    while (1) {
        # Draw a single frame
        for (x = 1; x <= width; x++) {
            # Pick a random character for the current position
            char = char_array[int(rand() * num_chars) + 1]

            # Erase the character at the top of the trail
            y_erase = drops[x] - speeds[x]
            if (y_erase >= 1 && y_erase <= height) {
                printf "\033[%d;%dH ", y_erase, x
            }

            # Draw the head of the drop in bright white
            y_head = drops[x]
            if (y_head >= 1 && y_head <= height) {
                printf "\033[%d;%dH\033[1;37m%s\033[0m", y_head, x, char
            }

            # Draw the character just behind the head in green
            y_trail = drops[x] - 1
            if (y_trail >= 1 && y_trail <= height) {
                # Add a very low probability of a red character
                if (rand() < 0.001) { # Like, very small
                    printf "\033[%d;%dH\033[38;5;%dm%s\033[0m", y_trail, x, red_code, char
                } else {
                    # Otherwise, draw it in a random green shade
                    random_green_code = green_array[int(rand() * num_shades) + 1]
                    printf "\033[%d;%dH\033[38;5;%dm%s\033[0m", y_trail, x, random_green_code, char
                }
            }

            # Update drop position
            drops[x] += speeds[x]

            # Reset drop if it goes off screen
            if (drops[x] > height + 20) {
                drops[x] = -int(rand() * height)
                speeds[x] = int(rand() * 3) + 1
            }
        }
        fflush()
        if (system("sleep 0.07") != 0) {
            system("clear")
            printf "\033[2J\033[?25h\033[0m"
            exit
        }
    }
}

# Restore cursor on exit (e.g., Ctrl+C)
END {
    printf "\033[2J\033[?25h\033[0m"
    system("echo 'foo'")
    system("clear")
    system("clear")
}
