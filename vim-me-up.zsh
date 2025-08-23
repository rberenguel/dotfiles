# Except for the custom arrows and readline commands, everything here
# is from https://thevaluable.dev/zsh-install-configure-mouseless/

bindkey -v
export KEYTIMEOUT=1

# Shows a block cursor or a beamline cursor depending on whether you are
# in normal mode or insert mode in the terminal

cursor_mode() {
    cursor_block='\e[2 q'
    cursor_beam='\e[6 q'

    function zle-keymap-select {
        if [[ ${KEYMAP} == vicmd ]] ||
            [[ $1 = 'block' ]]; then
            echo -ne $cursor_block
        elif [[ ${KEYMAP} == main ]] ||
            [[ ${KEYMAP} == viins ]] ||
            [[ ${KEYMAP} = '' ]] ||
            [[ $1 = 'beam' ]]; then
            echo -ne $cursor_beam
        fi
    }

    zle-line-init() {
        echo -ne $cursor_beam
    }

    zle -N zle-keymap-select
    zle -N zle-line-init
}

cursor_mode

# Enable text objects

autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done

# Allow arrow keys to work in insert mode
# The code is terminal-specific. Press ctrl-v and quickly
# the arrow to display it in your terminal and adapt depending on that

bindkey -M viins '^[[A' up-line-or-search
bindkey -M viins '^[[B' down-line-or-search
bindkey -M viins '^[[C' forward-char
bindkey -M viins '^[[D' backward-char

# Make backspace work as expected
bindkey -M viins '^?' backward-delete-char

# Emacs-style bindings for insert mode
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^W' backward-kill-word
#bindkey -M viins '^R' history-incremental-search-backward

# Kill (cut) from cursor to the beginning of the line
bindkey -M viins '^U' backward-kill-line

# Yank (paste) the last killed text
bindkey -M viins '^Y' yank

# Word-wise movement and deletion (Alt+B, Alt+F, Alt+D)
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word
bindkey -M viins '^[d' kill-word

# Clear the screen
bindkey -M viins '^L' clear-screen
