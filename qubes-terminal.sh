#!/bin/sh

# Start a terminal in the current VM.
# I use it in my i3 config like this:
#   bindsym $mod+a exec --no-startup-id ~/bin/qubes-terminal.sh
# (pressing $mod+a opens the urxvt terminal in the active window's VM; dom0 otherwise)

term=urxvt

get_id() {
    local id=$(xprop -root _NET_ACTIVE_WINDOW)
    echo ${id##* } # extract id
}

get_vm() {
    local id=$(get_id)
    local vm=$(xprop -id $id | grep '_QUBES_VMNAME(STRING)')
    local vm=${vm#*\"} # extract vmname
    echo ${vm%\"*} # extract vmname
}

main() {
    local vm=$(get_vm)
    if [ -n "$vm" ]; then
        # run terminal in vm
        qubes-run "$vm:term"
    else
        # run terminal in dom0
        exec $term
    fi
}

main
