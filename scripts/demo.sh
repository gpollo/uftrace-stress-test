#!/usr/bin/bash

SESSION_NAME=demo

tmux -L "$SESSION_NAME" kill-session
tmux -L "$SESSION_NAME" new-session -d
tmux -L "$SESSION_NAME" split-window -h
tmux -L "$SESSION_NAME" select-pane -L
tmux -L "$SESSION_NAME" send-keys "vim main.c"
tmux -L "$SESSION_NAME" select-pane -R
tmux -L "$SESSION_NAME" send-keys "clear" ENTER
tmux -L "$SESSION_NAME" split-window -v
tmux -L "$SESSION_NAME" send-keys "clear" ENTER
tmux -L "$SESSION_NAME" split-window -v
tmux -L "$SESSION_NAME" send-keys "clear" ENTER
tmux -L "$SESSION_NAME" attach
