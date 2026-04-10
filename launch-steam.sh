#!/bin/bash
# SIGINT-Deck Steam Game Mode launcher
# Starts the service, opens the dashboard, stops on exit

# Start the monitoring service
systemctl --user start sigint-deck
sleep 2

# Wait for the web server to be ready
for i in $(seq 1 10); do
    if curl -s http://localhost:8085/ >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Open dashboard in Steam-friendly browser
# In game mode, this opens in the Steam overlay browser
# In desktop mode, this opens the default browser
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    xdg-open http://localhost:8085 2>/dev/null &
fi

echo "SIGINT-Deck monitoring active."
echo "Dashboard: http://localhost:8085"
echo "Press Ctrl+C or close this window to stop monitoring."

# Keep running until the user exits
# In Steam game mode, this keeps the "game" running
trap "systemctl --user stop sigint-deck; echo Stopped." EXIT
while systemctl --user is-active sigint-deck >/dev/null 2>&1; do
    sleep 5
done
