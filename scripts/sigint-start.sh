#!/bin/bash
# Start SIGINT-Deck monitoring
systemctl --user start sigint-deck
sleep 2
if systemctl --user is-active sigint-deck >/dev/null 2>&1; then
    notify-send "SIGINT-Deck" "Monitoring started on http://localhost:8085" -i network-wireless 2>/dev/null
    echo "SIGINT-Deck started. Dashboard: http://localhost:8085"
else
    notify-send "SIGINT-Deck" "Failed to start! Check: journalctl --user -u sigint-deck" -i dialog-error 2>/dev/null
    echo "Failed to start. Check: journalctl --user -u sigint-deck"
fi
