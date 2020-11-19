#!/usr/bin/python2

# I use this script in Qubes OS dom0 with i3 window manager to dynamicaly
# assign windows to workspaces. Qubes OS sets window class as <vm>:<app>, so
# this script takes the <vm> part and uses it as a workspace name.
#
# Setup:
# 1. Add this to i3 config:
#       assign [class=.*] _
# 2. Save this script as ~/bin/i3-dynamic-workspaces.py and start it using
#       ~/bin/i3-dynamic-workspaces.py &
#
# DEPENDENCY: python2-i3ipc
# BUG: script needs to be reloaded after i3 restart.

from i3ipc import Connection, Event
from time import sleep
import socket


def on_new_window(i3, e):
    class_split = e.container.window_class.split(':', 1)
    if len(class_split) == 1:
        class_split.insert(0, 'dom0')
    vm, app = class_split

    target_workspace = vm

    try:
        current_workspace = i3.get_tree().find_focused().workspace().name
    except AttributeError:
        current_workspace = ''

    print('on_new_window(): vm=%s, app=%s, target_workspace=%s, current_workspace=%s' % (vm, app, target_workspace, current_workspace))
    
    if target_workspace == 'dom0':
        target_workspace = current_workspace
        if not target_workspace:
            target_workspace = 'dom0'
    
    if current_workspace.startswith('%s:' % target_workspace):
        target_workspace = current_workspace

    if target_workspace.startswith('disp'):
        target_workspace = 'tmp-%s' % target_workspace
    cmd = []
    cmd.append('[con_id={id}] move window to workspace {w}'.format(id=e.container.id, w=target_workspace))
    if current_workspace == target_workspace:
        cmd.append('[con_id={id}] focus'.format(id=e.container.id))

    # Make sure floating windows are created in the center
    cmd.append('[con_id={id}] move position center'.format(id=e.container.id))

    cmd = ';'.join(cmd)
    print(cmd)
    i3.command(cmd)
    
i3 = Connection()

i3.on('window::new', on_new_window)

while True:
    try:
        i3.main()
    except socket.error as e:
        print("Error", e)
        sleep(1)
    print("Restarting i3 main loop...")

