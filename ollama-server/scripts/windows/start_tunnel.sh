#!/bin/bash
VPS_IP="YOUR_VPS_IP"
VPS_USER="root"
LOCAL_PORT=11434
REMOTE_PORT=11434

while true; do
    echo "Starting SSH tunnel..."
    ssh -N -R $REMOTE_PORT:localhost:$LOCAL_PORT $VPS_USER@$VPS_IP
    echo "Tunnel disconnected. Reconnecting in 5 seconds..."
    sleep 5
done
