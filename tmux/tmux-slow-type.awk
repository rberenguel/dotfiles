#!/usr/bin/awk -f

#
# Simulates human typing in tmux, including mistakes and corrections.
# Usage: awk -v text="..." [-v delay=0.05] [-v mistake_rate=0.01] -f slow_type.awk
#

BEGIN {
    if (text == "") {
        exit 1
    }
    if (delay == "") {
        delay = 0.05
    }
    if (mistake_rate == "") {
        mistake_rate = 0.01 # % typo per character
    }

    srand()
    wrong_chars = "asdfghjklqwertyuiopzxcvbnm"

    for (i = 1; i <= length(text); i++) {
        char = substr(text, i, 1)

        # 1. SIMULATE MISTAKES
        if (mistake_rate > 0 && char != " " && rand() < mistake_rate) {
            wrong_char_pos = 1 + int(rand() * length(wrong_chars))
            wrong_char = substr(wrong_chars, wrong_char_pos, 1)
            
            system("tmux send-keys -l -- '" wrong_char "'")
            system("sleep " delay * 4) # "Realization" pause
            system("tmux send-keys C-h") # Send Control-h for backspace
            system("sleep " delay * 2) # "Correction" pause
        }

        # 2. SEND THE CORRECT CHARACTER
        if (char == "'") {
            cmd = "tmux send-keys -l -- ''\\'''"
        } else {
            cmd = "tmux send-keys -l -- '" char "'"
        }
        system(cmd)

        # 3. CALCULATE A HUMAN-LIKE DELAY
        current_delay = delay * (0.5 + rand()) # Base random delay

        if (char == " ") {
            current_delay *= 3 # Longer pause between words
        } else if (char ~ /[,.]/) {
            current_delay *= 7 # Long pause for clause-ending punctuation
        } else if (char ~ /[A-Z]/) {
            current_delay *= 1.5 # Slight hesitation for capital letters
        }
        
        system("sleep " current_delay)
    }
}