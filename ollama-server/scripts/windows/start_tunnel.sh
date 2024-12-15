#!/bin/bash
VPS_IP="192.3.59.148"
VPS_USER="root"
LOCAL_PORT=11434
REMOTE_PORT=11434

echo "Starting SSH tunnel service at $(date)"
echo "Connecting to: $VPS_USER@$VPS_IP"

while true; do
    echo "Starting SSH tunnel with IPv4..."
    ssh -v -4 -N -R $REMOTE_PORT:127.0.0.1:$LOCAL_PORT $VPS_USER@$VPS_IP \
        -o "ExitOnForwardFailure=yes" \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "IPQoS=throughput"
    
    echo "Tunnel disconnected at $(date). Reconnecting in 5 seconds..."
    sleep 5
done