#zmodload zsh/zprof

bindkey -rM emacs '^P'

CASE_SENSITIVE="false"
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"
COMPLETION_WAITING_DOTS="true"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
TERM=xterm-256color

HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# -----------------------------------------------------------------------------
# -- Zinit stuff
# -----------------------------------------------------------------------------

if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

### End of Zinit's installer chunk

# --- Oh My Zsh Plugins ---
# The 'ice wait'0' lucid' command tells zinit to load the plugin
# in the background without blocking your prompt.

zinit ice lucid wait'0' pick"git.plugin.zsh" path"plugins/git"
zinit light ohmyzsh/ohmyzsh
zinit ice lucid wait'0' pick"macos.plugin.zsh" path"plugins/macos"
zinit light ohmyzsh/ohmyzsh
zinit ice lucid wait'0' pick"cp.plugin.zsh" path"plugins/cp"
zinit light ohmyzsh/ohmyzsh
zinit ice lucid wait'0' pick"gnu-utils.plugin.zsh" path"plugins/gnu-utils"
zinit light ohmyzsh/ohmyzsh
zinit ice lucid wait'0' pick"shrink-path.plugin.zsh" path"plugins/shrink-path"
zinit light ohmyzsh/ohmyzsh
zinit ice lucid wait'0'
zinit light junegunn/fzf

zinit ice lucid wait'0'
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# Potentially dangerous
zinit ice lucid wait'0' pick"colorize.plugin.zsh" path"plugins/colorize"
zinit light ohmyzsh/ohmyzsh

ZSHZ_CMD="j" # I prefer j for jumping
zinit load agkozak/zsh-z

SPACESHIP_PROMPT_ASYNC=true
eval "$(starship init zsh)"

# -----------------------------------------------------------------------------
# -- Custom crap
# -----------------------------------------------------------------------------

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/vim-me-up.zsh ] && source ~/vim-me-up.zsh
[ -f ~/secrets.zsh ] && source ~/secrets.zsh

# -----------------------------------------------------------------------------
# -- Cheap coloring in places
# --------------------

# LS_COLORS is used by GNU ls. LSCOLORS is used by BSD ls.
export LS_COLORS='fi=00:mi=00:mh=00:ln=01;36:or=01;31:di=01;34:ow=04;01;34:st=34:tw=04;34:'
LS_COLORS+='pi=01;33:so=01;33:do=01;33:bd=01;33:cd=01;33:su=01;35:sg=01;35:ca=01;35:ex=01;32'
export LSCOLORS='ExGxDxDxCxDxDxFxFxexEx'

# TREE_COLORS is used by GNU tree. It looks awful with underlined text, so we turn it off.
export TREE_COLORS=${LS_COLORS//04;}

# -----------------------------------------------------------------------------
# -- Aliases. TODO: cleanup
# -----------------------------------------------------------------------------

alias top="htop"
alias t=top
alias ag=rg
alias l="ls -lrthG"
alias git=hub

alias d='cd ~/Downloads'
alias ytdlpm='yt-dlp --use-postprocessor FFmpegCopyStream --ppa CopyStream:"-c:v libx264 -c:a aac -f mp4"'
alias ytdla='yt-dlp --audio-quality 0 -x '
alias yt='yt-dlp_macos'
alias c='gp-2.11'
alias k='kubectl'
alias cat='bat'

alias less='bat --paging always --plain'
alias mess='bat --paging always'
alias ll='ls -t | head -n1 | xargs less'
alias lh='ls -t | head -n1 | xargs head'
alias le='ls -t | head -n1 | xargs e'
alias lo='ls -t | head -n1 | xargs open'
alias s='echo "\n\e[33m=========================================================================================================================================\e[39m\n"'

fpath=($fpath ~/.zsh/completion)
alias stellaris="/Users/ruben/Library/Application\ Support/Steam/steamapps/common/Stellaris/stellaris.app/Contents/MacOS/stellaris"
alias notif="~/tmux-notify.awk"


#zprof
