[ -f ~/.zshrc.before ] && source ~/.zshrc.before

if [[ $FORCE_TMUX == '1' ]] && [[ ! -v TMUX ]] && [[ ! -v NVIM ]]; then
    tmux attach || tmux
    exit 0
fi

if [ $(uname) = 'Darwin' ] && ! [ -x "$(command -v brew)" ]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew bundle install --file ~/.dotfiles/Brewfile
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================== zinit start ================================ #
export ZINIT_HOME_DIR=${ZINIT_HOME_DIR:-$HOME/.zinit}
if [[ ! -d ${ZINIT_HOME_DIR} ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing zinit…%f"
    command mkdir -p ${ZINIT_HOME_DIR}
    command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git ${ZINIT_HOME_DIR}/bin && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%F" || \
        print -P "%F{160}▓▒░ The clone has failed.%F"
fi

source ${ZINIT_HOME_DIR}/bin/zinit.zsh

zinit light-mode for \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting

zinit light-mode for \
    hlissner/zsh-autopair \
    skywind3000/z.lua

zinit light-mode for \
    blockf \
    zsh-users/zsh-completions \
    atclone="dircolors -b LS_COLORS > c.zsh" atpull='%atclone' pick='c.zsh' \
    trapd00r/LS_COLORS

zinit ice as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' \
    atpull'%atclone' make'install' pick"$ZPFX/bin/git-cal"
zinit light k4rthik/git-cal

zinit ice wait lucid as=program pick="$ZPFX/bin/(fzf|fzf-tmux)" \
    atclone="./install --bin; cp bin/(fzf|fzf-tmux) $ZPFX/bin" \
    atpull='%atclone' \
    multisrc='shell/*.zsh'
zinit light junegunn/fzf

function zvm_config() {
    ZVM_CURSOR_STYLE_ENABLED=false
}
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit ice depth=1
zinit light romkatv/powerlevel10k

export NVM_COMPLETION=true
export NVM_SYMLINK_CURRENT="true"
zinit wait lucid light-mode for lukechilds/zsh-nvm

zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::gitignore

# ================================ zinit end ================================= #
if type brew &>/dev/null; then
    FPATH=$FPATH:$(brew --prefix)/share/zsh/site-functions
    autoload -Uz compinit
    compinit
fi

bindkey -v

# run the command, but won't clear the actual commandline
bindkey '^\'    accept-and-hold

# Customize to your needs...
[ -f ~/.shared_profile.zsh ] && source ~/.shared_profile.zsh

# ================================ envs ================================= #
export PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple
export PIPENV_PYPI_MIRROR=${PIP_INDEX_URL}

export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/

export BAT_THEME='kanagawa'

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# https://github.com/romkatv/powerlevel10k/issues/524
export GPG_TTY=$TTY

export FZF_DEFAULT_OPTS="
--color fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
--color info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54
--black
--pointer ➤
--exact
--info=inline
"

export GOPATH=${HOME}/go

function _prepend_path() {
    if [[ -d "$1" ]] && [[ ":${PATH}:" != *":$1:"* ]]; then
        PATH="${1}${PATH:+":$PATH"}"
    fi
}

function _append_path() {
    if [[ -d "$1" ]] && [[ ":${PATH}:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}

_prepend_path "${HOME}/.cargo/bin"
export PYENV_ROOT="$HOME/.pyenv"
_prepend_path "${PYENV_ROOT}/bin"
_prepend_path "${HOME}/.krew/bin"
_prepend_path "${HOME}/.wasme/bin"
_prepend_path "${HOME}/.local/share/bob/nvim-bin"
_prepend_path "${HOME}/.local/bin"
_prepend_path "${GOPATH}/bin"
export PATH

unfunction _prepend_path
unfunction _append_path

# python
[ -f ~/.startup.py ] && export PYTHONSTARTUP=${HOME}/.startup.py

if [[ -d "${PYENV_ROOT}" ]]; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
else
    unset PYENV_ROOT
fi

# ================================ aliases ================================= #
function _exists() { (( $+commands[$1])) }

_exists eza     && alias ls='eza --icons --git'
_exists htop    && alias top='htop'
_exists fdfind  && alias fd='fdfind'
_exists batcat  && alias bat='batcat'
_exists bat     && alias cat='bat'
_exists free    && alias free='free -h'
_exists less    && export PAGER=less
_exists less    && alias more='less'
_exists kubectl && alias kubesys='kubectl --namespace kube-system'
_exists ag      && alias grep='ag'
_exists rg      && alias grep='rg'
_exists curlie  && alias curl='curlie'
export DIRENV_LOG_FORMAT=
_exists direnv  && eval "$(direnv hook zsh)"
_exists docker  && alias dis='docker images | sort -k7 -h'
_exists neovide && alias vide='neovide'

alias ll='ls -l'
alias llh='ls -lh'

alias cpwd='pwd | clipcopy'

alias piplist="pip freeze | awk -F'==' '{print \$1}'"

alias genpass="date +%s | sha256sum | base64 | head -c 14"

if _exists nvim; then
    export EDITOR=nvim
    export VISUAL=nvim
    export MANPAGER="nvim +Man!"
    alias vim='nvim'
    alias vi='nvim'
fi

unfunction _exists

# ================================ functions ================================= #

function howto() {
    # read input from flags or stdin if no tty
    local input=$(if [ -t 0 ]; then echo $@; else cat -; fi)

    # escape double quotes
    input=${input//\"/\\\"}

    # suppressing '[job_id] pid' output
    setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    spinner --style dots &
    local spinner_pid=$!

    # trap SIGINT to handle Ctrl-C
    trap 'kill $spinner_pid 2>/dev/null' INT

    local output=$(nvim --headless -c "Howto! ${input}")

    kill $spinner_pid 2>/dev/null
    wait

    print -z "$output"
}

function tgo() {
    local tgo_path="${HOME}/.tmp/tgo"
    mkdir -p "${tgo_path}"

    # check if the first argument is exists
    if [[ -n "${1}" ]]; then
        local tmp="$(mktemp -p ${tgo_path} -d "${1}_$(date +%Y%m%d)_XXXXXXXX")"
        (
            cd ${tmp}
            go mod init "$(basename "${tmp}")"
            cat > "main.go" << EOF
package main

func main() {
}
EOF

            cat > "main_test.go" << EOF
package main_test

import (
	"os"
	"testing"
)

func TestMain(m *testing.M) {
	os.Exit(m.Run())
}

func BenchmarkMain(b *testing.B) {
	b.ReportAllocs()
	for n := 0; n < b.N; n++ {

	}
}
EOF

            nvim -p main.go main_test.go
            echo ${tmp}
        )
    else
        local choice=$(find "${tgo_path}" -maxdepth 1 -type d -exec basename {} \; | fzf) && \
            (cd "${tgo_path}/${choice}" && \
            nvim -p main.go main_test.go)
    fi
}

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function zsh-stats() {
  fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n25
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
