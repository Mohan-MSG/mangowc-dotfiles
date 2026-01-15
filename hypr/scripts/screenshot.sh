#!/bin/bash

# Alternative Screenshot Script
# Using grim and slurp directly for maximum reliability

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# Options menu
options="󰄀 Select Area\n󰹑 Fullscreen (Current Monitor)\n󰖭 Fullscreen (All)\n󰈈 Active Window\n📋 Clipboard History"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Screenshot" -l 5)

if [ -z "$chosen" ]; then
    exit 0
fi

# Generate filename
FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
FILEPATH="$SAVE_DIR/$FILENAME"

case "$chosen" in
    "󰄀 Select Area")
        # Use slurp to get geometry, then grim to capture
        GEOM=$(slurp)
        if [ -z "$GEOM" ]; then exit 1; fi
        grim -g "$GEOM" "$FILEPATH"
        ;;
    "󰹑 Fullscreen (Current Monitor)")
        # Get the name of the focused monitor
        MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
        grim -o "$MONITOR" "$FILEPATH"
        ;;
    "󰖭 Fullscreen (All)")
        # Simple grim with no arguments captures all
        grim "$FILEPATH"
        ;;
    "󰈈 Active Window")
        # Get geometry of active window
        GEOM=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$GEOM" "$FILEPATH"
        ;;
    "📋 Clipboard History")
        cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
        exit 0
        ;;
esac

# If the file was created, copy it to clipboard and notify
if [ -f "$FILEPATH" ]; then
    wl-copy -t image/png < "$FILEPATH"
    notify-send "Screenshot Captured" "Saved to $FILENAME and copied to clipboard" -i camera-photo
else
    notify-send "Screenshot Failed" "Could not capture image" -u critical
fi
