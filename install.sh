#! /usr/bin/env sh

NOW=`date "+%m%d%H%M%Y"`

echo "Config tmux:"
if [ -e $HOME/.tmux.conf ]; then
    echo ".tmux.conf already exists"
    echo "Backup .tmux.conf to .tmux.conf.bak.$NOW"
    mv $HOME/.tmux.conf $HOME/.tmux.conf.bak.$NOW
fi
echo "Link tmux.conf"
ln -s $PWD/tmux.conf $HOME/.tmux.conf
echo "Done."

echo "Config git"
if [ -e $HOME/.gitconfig ]; then
    echo ".gitconfig already exists"
    echo "Backup .gitconfig to .gitconfig.bak.$NOW"
    mv $HOME/.gitconfig $HOME/.gitconfig.bak.$NOW
fi
echo "Link gitconfig"
ln -s $PWD/gitconfig $HOME/.gitconfig
echo "Done."

echo "config vim:"
curl https://raw.githubusercontent.com/Xuyuanp/vimrc/master/install.sh | sh
echo "Done."
