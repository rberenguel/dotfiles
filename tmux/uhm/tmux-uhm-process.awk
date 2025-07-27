#!/usr/bin/env gawk -f

# SCRIPT 1: PROCESSOR & LAUNCHER
# Finds matches, writes annotated content and match data to temp files,
# then launches the displayer script in a popup.

@include "rules.awk"

BEGIN {
    awkpath = ENVIRON["AWKPATH"]
    # --- Configuration ---
    CAPTURE_FILE  = "/tmp/tmux-capture.dump"
    CONTENT_FILE  = "/tmp/tmux-annotated-content.dump"
    MATCH_FILE    = "/tmp/tmux-matches.tmp"
    INTERACTOR    = "tmux-uhm-display.awk"
    # --- State ---
    delete matches
    label_idx = 0

    # --- Step 1: Capture only the visible pane to a temporary file ---
    "tmux display-message -p '#{scroll_position}'"  | getline scroll_p; close("tmux display-message -p '#{scroll_position}'")
    "tmux display-message -p '#{=#{scroll_position}+#{pane_height}-1}'"  | getline scroll_pe; close("tmux display-message -p '#{=#{scroll_position}+#{pane_height}-1}'")
    capture_cmd = "tmux capture-pane -p -S 0 -E " scroll_pe
    system(capture_cmd " > " CAPTURE_FILE)

    # --- Step 2: Process the capture file ---
    # Create the two output files: one for key:path mappings, one for annotated content.
    system(": > " MATCH_FILE)
    system(": > " CONTENT_FILE)

    while ((getline line < CAPTURE_FILE) > 0) {
        # This safe loop avoids modifying 'line' while iterating over it.
        original_line = line
        processed_line = ""
        last_pos = 1
        for(i=1; i<=_regex_count; i++){
            while (match(substr(original_line, last_pos), REGEXES[i])) {
                match_start = last_pos + RSTART - 1
                match_end = match_start + RLENGTH

                processed_line = processed_line substr(original_line, last_pos, match_start - last_pos)
                the_match = substr(original_line, match_start, RLENGTH)

                if (label_idx < 26) {
                    key = sprintf("%c", 97 + label_idx)
                    # Write the mapping to the match file.
                    printf "%s:%s\n", key, the_match >> MATCH_FILE
                    # Write a simple, unique marker to the content file.
                    processed_line = processed_line "%%LABEL_" key "_" i "_%%"
                    label_idx++
                } else {
                    # If we run out of labels, just pass the match through.
                    processed_line = processed_line the_match
                }
                last_pos = match_end
            }
        }
        processed_line = processed_line substr(original_line, last_pos)
        print processed_line >> CONTENT_FILE
    }
    # Clean up.
    close(CAPTURE_FILE); system("rm " CAPTURE_FILE)
    close(MATCH_FILE)
    close(CONTENT_FILE)

    # --- Step 3: Launch the popup with the interactor script ---
    cwd = ENVIRON["UHMPATH"]
    # --- Step 3: Launch the popup with the correct geometry ---
    # Query tmux for the current pane's geometry and capture the output.
    "tmux display-message -p '#{pane_width}'"  | getline pane_w; close("tmux display-message -p '#{pane_width}'")
    "tmux display-message -p '#{pane_height}'" | getline pane_h; close("tmux display-message -p '#{pane_height}'")
    "tmux display-message -p '#{pane_left}'"   | getline pane_l; close("tmux display-message -p '#{pane_left}'")
    "tmux display-message -p '#{pane_top}'"    | getline pane_t; close("tmux display-message -p '#{pane_top}'")

    #cmd = "tmux popup -E -w 100% -h 100% -- env AWKPATH=" awkpath " " cwd "/" INTERACTOR
    cmd = "tmux popup -B -E -w " pane_w " -h " pane_h " -x " pane_l " -y " pane_t " -- env AWKPATH=" awkpath " " cwd "/" INTERACTOR
    system(cmd)
}