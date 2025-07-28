#!/usr/bin/env gawk -f

BEGIN {
    CAPTURE_FILE  = "/tmp/tmux-capture.dump"
    CAPTURE_FILE_  = "/tmp/tmux-capture_.dump"
    CONTENT_FILE  = "/tmp/tmux-annotated-content.dump"
    MATCH_FILE    = "/tmp/tmux-matches.tmp"
    L_DELIM = "⠐"
    R_DELIM = "⠂"

    if (mode=="parse"){
        # Finds matches, writes annotated content and match data to temp files,
        # then launches the displayer script in a popup.
        awkpath = ENVIRON["AWKPATH"]
        # --- Configuration ---
        
        INTERACTOR    = "tmux-uhm.awk"
        # --- State ---
        delete matches
        label_idx = 0

        # --- Step 1: Capture only the visible pane to a temporary file ---
        "tmux display-message -p '#{scroll_position}'"  | getline scroll_p; close("tmux display-message -p '#{scroll_position}'")
        "tmux display-message -p '#{=#{scroll_position}+#{pane_height}-1}'"  | getline scroll_pe; close("tmux display-message -p '#{=#{scroll_position}+#{pane_height}-1}'")
        capture_cmd = "tmux capture-pane -p -S 0 -E " scroll_pe
        system(capture_cmd " > " CAPTURE_FILE_)
        clean_last_empty_cmd = "awk '{if (p) print p; p=$0} END {if (p !~ /^\\s*$/) print p}' " CAPTURE_FILE_ " > " CAPTURE_FILE
        system(clean_last_empty_cmd)

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
        close(CAPTURE_FILE); #system("rm " CAPTURE_FILE)
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
        _rules = ARGV[1]
        _gawk = ARGV[0]
        cmd = "tmux popup -B -E -w " pane_w " -h " pane_h " -x " pane_l " -y " pane_t " -- " _gawk " -f " _rules " -f" cwd "/" INTERACTOR " -v mode=display"
        system(cmd)
        
    }

    if(mode=="display"){
        COLORS[""] = ""
        preload_colors()
        # Reads annotated files, renders final output, and uses getkey() for interaction.
        # --- Colors ---
        DULL          = "\033[38;5;240m"
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
                label_display = LABEL_COLOR L_DELIM key R_DELIM RESET " "
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
                system(sprintf("tmux set-buffer -w '%s' && tmux save-buffer - | pbcopy", path))
                system(sprintf("tmux display-message -d 1000 'Copied %s'", path))
            }
        }
    }
}

function colorize(message, color_name, _code) {
    _code = COLORS[color_name]
    if (_code == "") {
        return message
    }
    return "\033[" _code "m" message "\033[0m"
}

function getkey(prompt,   # Local variables
                key, cmd) {
    #printf "%s", prompt
    # Set terminal, read char, restore terminal
    system("stty raw -echo")
    cmd = "dd if=/dev/tty bs=1 count=1 2>/dev/null"
    if ((cmd | getline key) > 0) {}
    close(cmd)
    system("stty -raw echo")

    #printf "\n" # Move to a new line after input
    return key
}

function preload_colors() {
    # Text Styles
    COLORS["reset"]     = "0"
    COLORS["bold"]      = "1"
    COLORS["dim"]       = "2"
    COLORS["underline"] = "4"
    COLORS["blink"]     = "5"
    COLORS["reverse"]   = "7"

    # 8 Normal Foreground Colors
    COLORS["black"]   = "30"; COLORS["red"]     = "31"
    COLORS["green"]   = "32"; COLORS["yellow"]  = "33"
    COLORS["blue"]    = "34"; COLORS["magenta"] = "35"
    COLORS["cyan"]    = "36"; COLORS["white"]   = "37"

    # 8 Bright Foreground Colors
    COLORS["light_black"]   = "90"; COLORS["light_red"]     = "91"
    COLORS["light_green"]   = "92"; COLORS["light_yellow"]  = "93"
    COLORS["light_blue"]    = "94"; COLORS["light_magenta"] = "95"
    COLORS["light_cyan"]    = "96"; COLORS["light_white"]   = "97"

    # 8 Normal Background Colors
    COLORS["bg_black"]   = "40"; COLORS["bg_red"]     = "41"
    COLORS["bg_green"]   = "42"; COLORS["bg_yellow"]  = "43"
    COLORS["bg_blue"]    = "44"; COLORS["bg_magenta"] = "45"
    COLORS["bg_cyan"]    = "46"; COLORS["bg_white"]   = "47"

    # 8 Bright Background Colors
    COLORS["bg_light_black"]   = "100"; COLORS["bg_light_red"]     = "101"
    COLORS["bg_light_green"]   = "102"; COLORS["bg_light_yellow"]  = "103"
    COLORS["bg_light_blue"]    = "104"; COLORS["bg_light_magenta"] = "105"
    COLORS["bg_light_cyan"]    = "106"; COLORS["bg_light_white"]   = "107"

    # Style combinations (examples)
    COLORS["bold_red"] = "1;31"; COLORS["bold_green"] = "1;32"
    COLORS["bold_blue"] = "1;34";
    COLORS["highlight"] = "48;5;226;38;5;16" # Yellow background, black text
    #

    # -- Solarized Dark Palette --

    # Foreground Accents (38;5;... is for foreground)
    COLORS["solar_yellow"]  = "38;5;136";  COLORS["solar_orange"] = "38;5;166"
    COLORS["solar_red"]     = "38;5;160";  COLORS["solar_magenta"]= "38;5;161"
    COLORS["solar_violet"]  = "38;5;61";   COLORS["solar_blue"]   = "38;5;33"
    COLORS["solar_cyan"]    = "38;5;37";   COLORS["solar_green"]  = "38;5;106"

    # Foreground Content
    COLORS["solar_fg"]        = "38;5;244"; # base0
    COLORS["solar_fg_light"]  = "38;5;245"; # base1

    # Backgrounds (48;5;... is for background)
    COLORS["solar_bg_dark"]     = "48;5;235"; # base02
    COLORS["solar_bg_darkest"]  = "48;5;234"; # base03
    COLORS["solar_bg_light"]    = "48;5;254"; # base2
    COLORS["solar_bg_lightest"] = "48;5;230"; # base3

    # Pre-combined "Decent" Highlight Styles ✨
    # (Using solar_bg_dark as the background)
    COLORS["highlight_yellow"]  = "48;5;235;38;5;136"
    COLORS["highlight_orange"]  = "48;5;235;38;5;166"
    COLORS["highlight_red"]     = "48;5;235;38;5;160"
    COLORS["highlight_magenta"] = "48;5;235;38;5;161"
    COLORS["highlight_violet"]  = "48;5;235;38;5;61"
    COLORS["highlight_blue"]    = "48;5;235;38;5;33"
    COLORS["highlight_cyan"]    = "48;5;235;38;5;37"
    COLORS["highlight_green"]   = "48;5;235;38;5;106"
    COLORS["highlight_inverted"]= "48;5;245;38;5;235" # Dark text on light background
}