#!/bin/bash
# Calculate CPU usage
read cpu a b c idle rest < /proc/stat
total1=$((a+b+c+idle))
idle1=$idle

sleep 0.5

read cpu a b c idle rest < /proc/stat
total2=$((a+b+c+idle))
idle2=$idle

diff_total=$((total2-total1))
diff_idle=$((idle2-idle1))

if [ "$diff_total" -eq 0 ]; then
    echo "0"
else
    # Calculate percentage
    usage=$(( (100 * (diff_total - diff_idle)) / diff_total ))
    echo $usage
fi
