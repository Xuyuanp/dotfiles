# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[ -f ~/.zshrc.before ] && source ~/.zshrc.before

# =============================== zinit start ================================ #
export ZINIT_HOME_DIR=${ZINIT_HOME_DIR:-$HOME/.zinit}
if [[ ! -d ${ZINIT_HOME_DIR} ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing zinit…%f"
    command mkdir -p ${ZINIT_HOME_DIR}
    command git clone --depth=1 https://github.com/zdharma/zinit.git ${ZINIT_HOME_DIR}/bin && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%F" || \
        print -P "%F{160}▓▒░ The clone has failed.%F"
fi

source ${ZINIT_HOME_DIR}/bin/zinit.zsh

zinit light-mode for \
    zsh-users/zsh-autosuggestions \
    zdharma/fast-syntax-highlighting

zinit light-mode for \
    hlissner/zsh-autopair \
    skywind3000/z.lua

zinit light-mode for \
    blockf \
    zsh-users/zsh-completions \
    atclone="dircolors -b LS_COLORS > c.zsh" atpull='%atclone' pick='c.zsh' \
    trapd00r/LS_COLORS

zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::dotenv
zinit snippet OMZP::gitignore

zinit ice as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' \
    atpull'%atclone' make'install' pick"$ZPFX/bin/git-cal"
zinit light k4rthik/git-cal

zinit ice as"program" pick"bin/git-dsf"
zinit light zdharma/zsh-diff-so-fancy

zinit ice wait lucid as=program pick="$ZPFX/bin/(fzf|fzf-tmux)" \
    atclone="./install --bin; cp bin/(fzf|fzf-tmux) $ZPFX/bin" \
    atpull='%atclone' \
    multisrc='shell/*.zsh'
zinit light junegunn/fzf

zinit ice depth=1
zinit light romkatv/powerlevel10k

# ================================ zinit end ================================= #

zpcompinit; zpcdreplay

bindkey -v

_exists() { (( $+commands[$1])) }

_exists exa     && alias ls='exa --icons --git'
_exists htop    && alias top='htop'
_exists fdfind  && alias fd='fdfind'
_exists batcat  && alias bat='batcat'
_exists free    && alias free='free -h'
_exists less    && export PAGER=less
_exists kubectl && alias kubesys='kubectl --namespace kube-system'

if _exists nvim; then
    export EDITOR=nvim
    export VISUAL=nvim
    export MANPAGER="nvim +Man!"
    alias vim='nvim'
    alias vi='nvim'
fi

unfunction _exists

[ -f ~/.startup.py ] && export PYTHONSTARTUP=${HOME}/.startup.py

# alias
alias ll='ls -l'
alias llh='ls -lh'

alias cpwd='pwd | clipcopy'

alias dis="docker images | sort -k7 -h"

alias piplist="pip freeze | awk -F'==' '{print \$1}'"

alias genpass="date +%s | sha256sum | base64 | head -c 14"

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S'):" $*
}

export PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple
export PIPENV_PYPI_MIRROR=${PIP_INDEX_URL}

export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node

export BAT_THEME='gruvbox-dark'

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

function tgo() {
    tmp="$(mktemp -p ${HOME}/.tmp -d "tgo_$(date +%Y%m%d)_XXXXXXXX")"
    cat > "${tmp}/main.go" << EOL
package main

func main() {
}
EOL

    cat > "${tmp}/main_test.go" << EOL
package main_test

import "testing"

func TestMain(t *testing.T) {

}

func BenchmarkMain(b *testing.B) {
    b.ReportAllocs()
    for n := 0; n < b.N; n++ {

    }
}
EOL

    printf 'module %s\n' "$(basename "${tmp}")" > "${tmp}/go.mod"
    (
        cd ${tmp}
        vim -p main.go main_test.go
        echo ${tmp}
    )
}

# Customize to your needs...
[ -f ~/.shared_profile.zsh ] && source ~/.shared_profile.zsh

[ -f ~/.zshrc.after ] && source ~/.zshrc.after

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export BAT_THEME='gruvbox-dark'

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

export PATH=${HOME}/.cargo/bin:${PATH}

export GOPATH=${HOME}/go
export PATH=${GOPATH}/bin:${PATH}
