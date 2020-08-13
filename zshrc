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

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma/fast-syntax-highlighting

zinit snippet OMZP::colored-man-pages
zinit snippet OMZL::clipboard.zsh

zinit ice as"command" make"PREFIX=$ZPFX install" \
    atclone"cp contrib/fzy-* $ZPFX/bin/" \
    atpull='%atclone' \
    pick"$ZPFX/bin/fzy*"
zinit load jhawthorn/fzy

zinit load b4b4r07/enhancd

zinit ice atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" nocompile'!'
zinit light trapd00r/LS_COLORS

zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions

zinit ice from"gh-r" as"program" atload'!eval $(starship init zsh)' pick'**/starship'
zinit load starship/starship

zinit ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX" nocompile
zinit light tj/git-extras

zinit ice as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' \
    atpull'%atclone' make'install' pick"$ZPFX/bin/git-cal"
zinit light k4rthik/git-cal

zinit ice as"program" pick"bin/git-dsf"
zinit light zdharma/zsh-diff-so-fancy

zinit ice as'program' make'build' pick'bin/go-md2man'
zinit light cpuguy83/go-md2man

zinit as"program" make'DESTDIR=$ZPFX install' atclone='direnv hook zsh > zhook.zsh' \
    atpull='%atclone' \
    pick"direnv" src'zhook.zsh' for \
    direnv/direnv

if [[ "$OSTYPE" == "darwin"* ]]; then
    zinit ice as"program" pick"yank" make"YANKCMD=pbcopy"
else
    zinit ice as"program" pick"yank" make
fi
zinit light mptre/yank

zinit ice wait lucid as=program pick="bin/(fzf|fzf-tmux)" \
    atclone="./install --bin" \
    atpull='%atclone' \
    multisrc='shell/*.zsh'
zinit light junegunn/fzf

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

export FZF_DEFAULT_OPTS='
--color fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
--color info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54
'
