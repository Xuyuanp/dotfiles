#! /usr/bin/env bash

export NOW=`date "+%m%d%H%M%Y"`

bold() {
    echo -e "\033[01m$*\033[0m"
}

green() {
    echo -e "\033[32m$*\033[0m"
}

yellow() {
    echo -e "\033[33m$*\033[0m"
}

red() {
    echo -e "\033[31m$*\033[0m"
}

prefix='==>'

info() {
    echo -e "$(green $prefix) $(bold $*)"
}

warn() {
    echo -e "$(yellow $prefix) $(bold $*)"
}

error() {
    echo -e "$(red $prefix) $(bold $*)"
    exit 1
}

help() {
    echo -e `bold "Usage:"`
    echo -e "    $0 [tmux|git|vim|all]"
}

config_vim() {
    info "Config vim:"
    if [ -e $HOME/.vim/.42 ]; then
        info "vimrc repo found, just update it"
        cd ~/.vim && source update.sh && info "Done" && return
    else
        curl https://raw.githubusercontent.com/Xuyuanp/vimrc/master/install.sh | sh && info "Done." && return
    fi
    error "Failed"
}

config_git() {
    info "Config git"
    git config --global include.path $PWD/gitconfig && info "Done." && return
    error "Failed."
}

config_tmux() {
    info "Config tmux:"
    info "installing tpm"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    if [ -e $HOME/.tmux.conf ]; then
        warn ".tmux.conf already exists"
        info "Backup .tmux.conf to .tmux.conf.bak.$NOW"
        mv $HOME/.tmux.conf $HOME/.tmux.conf.bak.$NOW
    fi
    info "Link tmux.conf"
    ln -s $PWD/tmux.conf $HOME/.tmux.conf
    info "Done."
}

config_all() {
    config_git
    config_tmux
    config_vim
}

if [ $# -eq 0 ] || [ "$1" =  "all" ]; then
    config_all
else
    for name in $*; do
        case "$name" in
            vim)
                config_vim
                ;;
            tmux)
                config_tmux
                ;;
            git)
                config_git
                ;;
            help)
                help
                ;;
            *)
                error "$name Didn't match anything"
        esac
    done
fi

unset NOW
