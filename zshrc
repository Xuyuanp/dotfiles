[ -f ~/.zshrc.before ] && source ~/.zshrc.before

if [[ $FORCE_TMUX == '1' ]] && [[ ! -v TMUX ]] && [[ ! -v NVIM ]]; then
    tmux attach || tmux
    exit 0
fi

if [ $(uname) = 'Darwin' ]; then
    if ! [ -x "$(command -v brew)" ]; then
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    FPATH=$FPATH:$(brew --prefix)/share/zsh/site-functions
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================== zinit start ================================ #
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light hlissner/zsh-autopair
zinit light zsh-users/zsh-completions

export NVM_COMPLETION=true
export NVM_SYMLINK_CURRENT="true"
zinit wait lucid light-mode for lukechilds/zsh-nvm

zvm_after_init_commands+=('[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh')
zvm_config() {
    ZVM_CURSOR_STYLE_ENABLED=true
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLOCK
}
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZP::gitignore

autoload -Uz compinit && compinit
zinit light Aloxaf/fzf-tab
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --git -l --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons --git -l --color=always $realpath'

# ================================ zinit end ================================= #

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# run the command, but won't clear the actual commandline
bindkey '^\' accept-and-hold

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
_prepend_path "${GOPATH}/bin"
export PATH

unfunction _prepend_path
unfunction _append_path

# python
[ -f ~/.startup.py ] && export PYTHONSTARTUP=${HOME}/.startup.py

if [[ -d "${PYENV_ROOT}" ]]; then
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
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
_exists direnv  && export DIRENV_LOG_FORMAT='' && eval "$(direnv hook zsh)"
_exists docker  && alias dis='docker images | sort -k7 -h'
_exists neovide && alias vide='neovide'
_exists zoxide  && eval "$(zoxide init zsh)"
_exists fzf     && [ ! -f $HOME/.fzf.zsh ] && fzf --zsh > ~/.fzf.zsh

alias ll='ls -l'
alias llh='ls -lh'

alias cpwd='pwd | clipcopy'

alias piplist="pip freeze | awk -F'==' '{print \$1}'"

alias genpass="date +%s | sha256sum | base64 | head -c 14"

if _exists nvim; then
    export EDITOR=nvim
    export VISUAL=nvim
    alias vim='nvim'
    alias vi='nvim'
fi

function man() {
    if [ -t 1 ]; then
        # Output is a terminal, use Neovim
        MANPAGER='nvim +Man!' command man "$@"
    else
        MANPAGER='cat' command man "$@"
    fi
}

unfunction _exists

# ================================ functions ================================= #

function howto() {
    local input
    if [ $# -gt 0 ]; then
        input="$@"
    elif [ ! -t 0 ]; then
        # read input from flags or stdin if no tty
        input=$(cat -)
    else
        # prompt user to enter input
        echo -n "> "
        read input
    fi

    # escape double quotes
    input=${input//\"/\\\"}

    # suppressing '[job_id] pid' output
    setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    spinner --style dots &
    local spinner_pid=$!

    # trap SIGINT to handle Ctrl-C
    trap 'kill $spinner_pid 2>/dev/null' INT TERM

    local output=$(echo $input | llm-cli)

    kill $spinner_pid 2>/dev/null
    wait

    print -z "$output"
}

# commit for me
function cfm() {
    # suppressing '[job_id] pid' output
    setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    spinner --style dots --suffix " Generating commit message..." &
    local spinner_pid=$!

    # trap SIGINT to handle Ctrl-C
    trap 'kill $spinner_pid 2>/dev/null' INT TERM

    local commit_msg
    if ! commit_msg=$(git diff --staged | llm-cli --role=commit 2>&1); then
        # Stop the spinning animation by killing its process
        kill $spinner_pid
        wait $spinner_pid 2>/dev/null  # Wait for the process to terminate and suppress error messages

      echo ''
      echo "Failed to generate the commit message: ${commit_msg}"
      echo "Set SKIP_LLM_GITHOOK=1 to skip this hook"
      exit 1
    fi

    kill $spinner_pid
    wait $spinner_pid 2>/dev/null
    git commit -e -m "${commit_msg}" $@
}

function tgo() {
    local tgo_path="${HOME}/workspace/tgo"
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
	"testing"
)

func BenchmarkMain(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()

	for b.Loop() {

	}
}
EOF

            nvim -p main.go main_test.go
            echo ${tmp}
        )
    else
        local choice=$(find "${tgo_path}" -maxdepth 1 -type d -exec basename {} \; | fzf)
        if [[ -z "${choice}" ]]; then
            return
        fi
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

function oc() {
    # Find available port
    local port=4096
    while [ $port -lt 5096 ]; do
        if ! lsof -i :$port >/dev/null 2>&1; then
            break
        fi
        port=$((port + 1))
    done

    export OPENCODE_PORT=$port
    opencode --port $port "$@"
}
