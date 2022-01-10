#!/usr/bin/env sh

awk '/^[a-z]/ && last {print "<small>",$0,"\t",last,"</small>"} {last=""} /^#/{last=$0}' ~/.config/sxhkd/sxhkdrc{,.common} |
    column -t -s $'\t' |
    rofi -dmenu -i -markup-rows -no-show-icons -theme ~/.config/bspwm/rofi/themes/keybindings.rasi
