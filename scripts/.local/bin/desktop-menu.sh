#!/bin/bash
choice=$(printf "Terminal\nFile Manager\nReload Waybar\nExit Hyprland\n" | wofi --dmenu --prompt "Desktop")

case "$choice" in
  "Terminal") kitty & ;;
  "File Manager") thunar & ;;
  "Reload Waybar") pkill waybar; sleep 0.5; waybar & disown ;;
  "Exit Hyprland") hyprctl dispatch 'hl.dsp.exit()' ;;
esac
