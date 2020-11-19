#!/bin/sh -e

# Stop idle window-less VMs to conserve memory.
# Save this script as ~/bin/stopidle.sh and add a cronjob:
# */5 * * * * DISPLAY=:0 $HOME/bin/stopidle.sh

get_windowed() {
  all_ids=$(xprop -root | grep '^_NET_CLIENT_LIST' | sed 's/^.*# //; s/,//g')
  if [ -z "$all_ids" ]; then
    return
  fi

  for id in $all_ids; do
    [ -n "$id" ] || continue
    xprop -id "$id" _QUBES_VMNAME | grep -Po '(?<=")[^"]+' || true
  done | sort -u
}

get_running() {
  qvm-ls --all --exclude dom0 --raw-data --fields NAME,STATE|grep -Po '^[^|]+(?=\|Running)'
}

shutdown_vm() {
  notify-send -u normal "Shutting down window-less vms:" "$@"
  qvm-shutdown --wait $@
}

stop_idle() {
  win_vms=$(get_windowed)

  idle_vms=

  if [ -z "$win_vms" ]; then
    echo "No windowed VMs?"
    exit 0
  fi

  for vm in $(get_running); do
    case "$vm" in
      sys-*|c-stats|my-music|work-mt|my) ;;
      *)
        found=false
        for win_vm in $win_vms; do
          if [ "$win_vm" = "$vm" ]; then
            found=true
          fi
        done
        if ! $found; then
          idle_vms="$idle_vms $vm"
        fi
    esac
  done

  if [ -n "$idle_vms" ]; then
    shutdown_vm "$idle_vms"
  fi
}

case "$1" in
  get_windowed) get_windowed ;;
  *) stop_idle ;;
esac

