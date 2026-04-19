#!/bin/bash

polybar top &

polybar bat &
echo $! > $HOME/.config/polybar/pid/bat.pid;sleep 0.2;polybar-msg -p $(cat $HOME/.config/polybar/pid/bat.pid) cmd hide

polybar net &
echo $! > $HOME/.config/polybar/pid/net.pid;sleep 0.2;polybar-msg -p $(cat $HOME/.config/polybar/pid/net.pid) cmd hide
