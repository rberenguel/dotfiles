#!/usr/bin/awk -f
BEGIN {
    if (ARGC < 4) {
        print "Usage: script <status> <pos_msg> <neg_msg> [delay_ms]" > "/dev/stderr"
        exit 1
    }

    # --- Configuration ---
    bg_success = "#859900"
    bg_failure = "#99322f"
    fg_dark_color   = "#111133"
    fg_light_color  = "#bbbbcc"
    status_bg  = "#552a36"      # Message background

    # --- Logic ---
    status  = ARGV[1]
    pos_msg = ARGV[2]
    neg_msg = ARGV[3]
    delay   = (ARGC > 4) ? ARGV[4] : 0

    if (status == 0) {
        icon     = "✓"
        message  = pos_msg
        bg_color = bg_success
        fg_color = fg_dark_color
    } else {
        icon     = "✗"
        message  = neg_msg
        bg_color = bg_failure
        fg_color = fg_light_color
    }

    # This version adds a final #[bg=%s] to fix the background on the right side of the capsule.
    cmd = sprintf("tmux display-message -d %d \"#[fg=%s,bg=%s]          #[fg=%s,bg=%s]#[fg=%s,bg=%s] %s %s  #[fg=%s,bg=%s]#[bg=%s]\"", \
        delay, bg_color, status_bg, bg_color, status_bg, fg_color, bg_color, icon, message, bg_color, status_bg, status_bg)
    system(cmd)
    exit
}