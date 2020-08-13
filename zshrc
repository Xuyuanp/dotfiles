# =============================== zinit start ================================ #
export ZINIT_HOME_DIR=${ZINIT_HOME_DIR:-$HOME/.zinit}
if [[ ! -d ${ZINIT_HOME_DIR} ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing zinit…%f"
    command mkdir -p ${ZINIT_HOME_DIR}
    command git clone https://github.com/zdharma/zinit.git ${ZINIT_HOME_DIR}/bin && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%F" || \
        print -P "%F{160}▓▒░ The clone has failed.%F"
fi

source ${ZINIT_HOME_DIR}/bin/zinit.zsh

# Two regular plugins loaded without investigating.
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma/fast-syntax-highlighting

# Plugin history-search-multi-word loaded with investigating.
zinit load zdharma/history-search-multi-word

zinit snippet OMZP::colored-man-pages
zinit snippet OMZL::clipboard.zsh

zinit load b4b4r07/enhancd

zinit ice atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" nocompile'!'
zinit light trapd00r/LS_COLORS

zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions

zplugin ice from"gh-r" as"program" atload'!eval $(starship init zsh)' pick'**/starship'
zplugin load starship/starship
# ================================ zinit end ================================= #

bindkey -v

# history config
HISTFILE="$HOME/.zhistory"
HISTSIZE=10000000
SAVEHIST=10000000

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

# case-insensitive TAB completion
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'

# Customize to your needs...
[ -f ~/.shared_profile.zsh ] && source ~/.shared_profile.zsh

# alias
alias ls='ls --color=auto'
alias ll='ls -l'
alias llh='ls -lh'

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export GPG_TTY=$(tty)

export EDITOR=nvim
export VISUAL=nvim
