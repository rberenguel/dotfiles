#!/usr/bin/env gawk -f

# SCRIPT 2: DISPLAYER & INTERACTOR
# Reads annotated files, renders final output, and uses getkey() for interaction.

@include "colorify.awk"
@include "rules.awk"

BEGIN {
    # --- Configuration ---
    CONTENT_FILE  = "/tmp/tmux-annotated-content.dump"
    MATCH_FILE    = "/tmp/tmux-matches.tmp"
    # --- Colors ---
    DULL          = "\033[38;5;240m"
    HIGHLIGHT     = "\033[48;5;226m\033[38;5;16m"
    LABEL_COLOR   = "\033[1;38;5;46m"
    RESET         = "\033[0m"
    # --- State ---
    delete matches

    # --- Step 1: Load the key-to-path mappings ---
    while ((getline data_line < MATCH_FILE) > 0) {
        sep = index(data_line, ":")
        key = substr(data_line, 1, sep - 1)
        path = substr(data_line, sep + 1)
        matches[key] = path
    }
    close(MATCH_FILE)
    system("rm " MATCH_FILE)

    # --- Step 2: Read annotated content, replace markers, and print ---
    while ((getline content_line < CONTENT_FILE) > 0) {
        for (key in matches) {
            path = matches[key]
            label_display = LABEL_COLOR "[" key "]" RESET " "
            for(i=1; i<=_regex_count; i++){
                _color = RULE_COLORS[i]
                match_display = colorize(path, _color) DULL
                gsub("%%LABEL_" key "_" i "_%%", label_display match_display, content_line)
            }
        }
        print DULL content_line RESET
    }
    close(CONTENT_FILE)
    system("rm " CONTENT_FILE)

    # --- Step 3: Prompt and handle keypress using getkey() ---
    if (length(matches) > 0) {
        prompt = sprintf("\n%s--- Press a letter to select a path ---%s", LABEL_COLOR, RESET)
        key_pressed = getkey(prompt)
        
        if (key_pressed in matches) {
            path = matches[key_pressed]
            gsub(/'/, "'\\''", path) # Escape single quotes for safety.
            # system(sprintf("tmux display-message -d 0 '%s which is key %s'", path, key_pressed))
            # TODO: figure out how to get this to work elsewhere
            system(sprintf("tmux set-buffer '%s' && tmux save-buffer - | pbcopy", path))
            system(sprintf("tmux display-message -d 1000 'Copied %s'", path))
        }
    }
}

# Your robust function to get a single key press.
function getkey(prompt,   # Local variables
                key, cmd) {
    printf "%s", prompt

    # Set terminal, read char, restore terminal
    system("stty raw -echo")
    cmd = "dd if=/dev/tty bs=1 count=1 2>/dev/null"
    if ((cmd | getline key) > 0) {}
    close(cmd)
    system("stty -raw echo")

    printf "\n" # Move to a new line after input
    return key
}