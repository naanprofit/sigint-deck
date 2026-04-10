#!/bin/bash
# Stop SIGINT-Deck monitoring
systemctl --user stop sigint-deck
sleep 1
if ! systemctl --user is-active sigint-deck >/dev/null 2>&1; then
    notify-send "SIGINT-Deck" "Monitoring stopped" -i network-offline 2>/dev/null
    echo "SIGINT-Deck stopped."
else
    notify-send "SIGINT-Deck" "Failed to stop!" -i dialog-error 2>/dev/null
    echo "Failed to stop."
fi
