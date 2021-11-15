#! /usr/bin/env sh
PATH=/usr/local/bin:/usr/bin:/bin

brew bundle dump --file ~/.dotfiles/Brewfile --quiet --force 2>&1 >/dev/null
