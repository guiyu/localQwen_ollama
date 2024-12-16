#!/bin/bash

# SSH tunnel configuration
VPS_IP="192.3.59.148"
VPS_USER="root"
LOCAL_PORT=11434
REMOTE_PORT=11434

# Log file settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="D:/workspaces/localQwen_ollama/ollama-server/logs"
LOG_FILE="${LOG_DIR}/tunnel.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting SSH tunnel script"
log "VPS: $VPS_USER@$VPS_IP"
log "Port forwarding: localhost:$LOCAL_PORT -> remote:$REMOTE_PORT"

while true; do
    log "Establishing SSH tunnel..."
    
    # SSH tunnel options:
    # -o StrictHostKeyChecking=no : Disable strict host key checking
    # -o UserKnownHostsFile=/dev/null : Don't save host keys
    # -o ServerAliveInterval=30 : Send keep-alive every 30 seconds
    # -o ServerAliveCountMax=3 : Disconnect after 3 failed keep-alives
    # -4 : Force IPv4
    # -N : Don't execute remote command
    # -R : Remote port forwarding
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=3 \
        -4 -N -R $REMOTE_PORT:localhost:$LOCAL_PORT $VPS_USER@$VPS_IP

    # Get exit code
    EXIT_CODE=$?
    log "SSH tunnel disconnected with exit code: $EXIT_CODE"
    
    # Wait before reconnecting
    log "Waiting 5 seconds before reconnecting..."
    sleep 5
done