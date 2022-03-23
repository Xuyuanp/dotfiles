#!/usr/bin/env bash

awk '/^[a-z]/ && last {print "<small>",$0,"\t",last,"</small>"} {last=""} /^#/{last=$0}' ~/.config/sxhkd/sxhkdrc |
    column -t -s $'\t' |
    rofi -dmenu -i -markup-rows -no-show-icons -theme ~/.config/bspwm/rofi/themes/keybindings.rasi
