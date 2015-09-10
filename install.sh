#! /usr/bin/env sh

export NOW=`date "+%m%d%H%M%Y"`

info() {
    echo "=> $1"
}

help() {
    echo "$0 [tmux|git|vim|all]"
}

config_vim() {
    info "Config vim:"
    curl https://raw.githubusercontent.com/Xuyuanp/vimrc/master/install.sh | sh
    info "Done."
}

config_git() {
    info "Config git"
    if [ -e $HOME/.gitconfig ]; then
        info ".gitconfig already exists"
        info "Backup .gitconfig to .gitconfig.bak.$NOW"
        mv $HOME/.gitconfig $HOME/.gitconfig.bak.$NOW
    fi
    info "Link gitconfig"
    ln -s $PWD/gitconfig $HOME/.gitconfig
    info "Done."
}

config_tmux() {
    info "Config tmux:"
    if [ -e $HOME/.tmux.conf ]; then
        info ".tmux.conf already exists"
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
                info "$name Didn't match anything"
        esac
    done
fi

unset NOW
