#!/usr/bin/bash

function tmux_kill_session() {
    local session="$1"

    tmux -L "$session" kill-session 2> /dev/null > /dev/null
}

function tmux_launch_session() {
    local session="$1"

    tmux_kill_session "$session"

    tmux -L "$session" new-session -d
    tmux -L "$session" send-keys "clear" ENTER
    tmux -L "$session" split-window -h
    tmux -L "$session" send-keys "clear" ENTER
    tmux -L "$session" split-window -h
    tmux -L "$session" send-keys "clear" ENTER
    tmux -L "$session" split-window -h
    tmux -L "$session" send-keys "clear" ENTER
    tmux -L "$session" select-layout main-horizontal

    #lxterminal --command "tmux -L $session attach"
}

function tmux_start_htop() {
    local session="$1"
    local pane="$2"

    tmux -L "$session" select-pane -t "$pane" >> /dev/null
    tmux -L "$session" send-keys " htop" Enter >> /dev/null
}

function tmux_start_uftrace() {
    local session="$1"
    local pane="$2"
    local binary="$3"
    local temp_directory="$4"

    if ! cp "$binary" "$temp_directory/$(basename $binary)"; then
        exit 1
    fi

    binary=$(basename "$binary")

    if ! chmod +x "$temp_directory/$binary"; then
        exit 1
    fi

    tmux -L "$session" select-pane -t "$pane" >> /dev/null
    tmux -L "$session" send-keys " cd $temp_directory" Enter >> /dev/null
    tmux -L "$session" send-keys " uftrace record --force -F hey $binary" Enter >> /dev/null
    sleep 1
    ps aux | grep -i "$binary" | grep -v grep | grep -v uftrace | awk '{print $2}'
}

function tmux_stop_program() {
    local session="$1"
    local pane="$2"

    tmux -L "$session" select-pane -t "$pane" >> /dev/null
    tmux -L "$session" send-keys "q" Enter
}

function tmux_close_uftrace() {
    local session="$1"
    local pane="$2"

    tmux -L "$session" select-pane -t "$pane" >> /dev/null
    tmux -L "$session" send-keys "q" BSpace
}

function uftrace_patch_function() {
    local client_pid="$1"
    local function="$2"

    uftrace client --pid "$client_pid" -P "$function"
}

function uftrace_unpatch_function() {
    local client_pid="$1"
    local function="$2"

    uftrace client --pid "$client_pid" -U "$function"
}

TMUX_SESSION=stress-test

function run_stress_tests() {
    local tmpdir_main
    local tmpdir_xray
    local tmpdir_fentry
    local pid_main
    local pid_xray
    local pid_fentry    

    tmux_launch_session "$TMUX_SESSION"
    tmpdir_main="./$(mktemp -d)"
    tmpdir_xray="./$(mktemp -d)"
    tmpdir_fentry="./$(mktemp -d)"

    mkdir -p "$tmpdir_main"
    mkdir -p "$tmpdir_xray"
    mkdir -p "$tmpdir_fentry"

    tmux_start_htop "$TMUX_SESSION" 0
    pid_main="$(tmux_start_uftrace "$TMUX_SESSION" 1 build/main-none "$tmpdir_main")"
    pid_xray="$(tmux_start_uftrace "$TMUX_SESSION" 2 build/main-xray "$tmpdir_xray")"
    pid_fentry="$(tmux_start_uftrace "$TMUX_SESSION" 3 build/main-fentry "$tmpdir_fentry")"

    for i in $(seq 40); do
        uftrace_patch_function "$pid_main" inner
        uftrace_patch_function "$pid_xray" inner
        uftrace_patch_function "$pid_fentry" inner
        printf "+"
        sleep 0.2

        uftrace_unpatch_function "$pid_main" inner
        uftrace_unpatch_function "$pid_xray" inner
        uftrace_unpatch_function "$pid_fentry" inner
        printf "-"
        sleep 0.2
    done

    sleep 5

    tmux_stop_program "$TMUX_SESSION" 1
    tmux_stop_program "$TMUX_SESSION" 2
    tmux_stop_program "$TMUX_SESSION" 3

    sleep 5

    tmux_close_uftrace "$TMUX_SESSION" 1
    tmux_close_uftrace "$TMUX_SESSION" 2
    tmux_close_uftrace "$TMUX_SESSION" 3

    sleep 5

    #tmux_kill_session "$TMUX_SESSION"

    rm -rfv "$tmpdir_main"
    rm -rfv "$tmpdir_xray"
    rm -rfv "$tmpdir_fentry"
}

function on_exit_handler {
    #tmux_kill_session "$TMUX_SESSION"
    echo
}
trap on_exit_handler EXIT


run_stress_tests
