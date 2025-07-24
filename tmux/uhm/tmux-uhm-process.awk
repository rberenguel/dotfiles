#!/usr/bin/awk -f

# SCRIPT 1: PROCESSOR & LAUNCHER
# Finds matches, writes annotated content and match data to temp files,
# then launches the displayer script in a popup.

BEGIN {
    # --- Configuration ---
    CAPTURE_FILE  = "/tmp/tmux-capture.dump"
    CONTENT_FILE  = "/tmp/tmux-annotated-content.dump"
    MATCH_FILE    = "/tmp/tmux-matches.tmp"
    MATCH_REGEX   = "/Users/ruben/[a-zA-Z0-9_./-]+"
    INTERACTOR    = "/Users/ruben/code/dotfiles/tmux/tmux-uhm-display.awk"
    # --- State ---
    delete matches
    label_idx = 0

    # --- Step 1: Capture only the visible pane to a temporary file ---
    capture_cmd = "tmux capture-pane -p -S '#{scroll_position}' -E '#{=#{scroll_position}+#{pane_height}-1}'"
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

        while (match(substr(original_line, last_pos), MATCH_REGEX)) {
            match_start = last_pos + RSTART - 1
            match_end = match_start + RLENGTH

            processed_line = processed_line substr(original_line, last_pos, match_start - last_pos)
            the_match = substr(original_line, match_start, RLENGTH)

            if (label_idx < 26) {
                key = sprintf("%c", 97 + label_idx)
                # Write the mapping to the match file.
                printf "%s:%s\n", key, the_match >> MATCH_FILE
                # Write a simple, unique marker to the content file.
                processed_line = processed_line "%%LABEL_" key "%%"
                label_idx++
            } else {
                # If we run out of labels, just pass the match through.
                processed_line = processed_line the_match
            }
            last_pos = match_end
        }
        processed_line = processed_line substr(original_line, last_pos)
        print processed_line >> CONTENT_FILE
    }
    # Clean up.
    close(CAPTURE_FILE); system("rm " CAPTURE_FILE)
    close(MATCH_FILE)
    close(CONTENT_FILE)

    # --- Step 3: Launch the popup with the interactor script ---
    system("tmux popup -E -w 100% -h 100% -- " INTERACTOR)
}