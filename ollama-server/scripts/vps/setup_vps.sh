#!/bin/bash

# Set error handling
set -e
log_file="/var/log/ollama_setup.log"
exec 1> >(tee -a "$log_file")
exec 2>&1

echo "Starting Ollama VPS setup..."

# Check necessary software
echo "Checking and installing required packages..."
apt-get update
apt-get install -y haproxy socat netcat

# Configure HAProxy
echo "Configuring HAProxy..."
haproxy_cfg="/etc/haproxy/haproxy.cfg"
cp $haproxy_cfg "${haproxy_cfg}.backup"

# Copy new configuration
cat > $haproxy_cfg << 'EOL'
global
    log /dev/log local0 debug
    log /dev/log local1 notice
    daemon
    maxconn 4096
    user haproxy
    group haproxy
    stats socket /var/run/haproxy.sock mode 660 level admin expose-fd listeners

defaults
    log global
    mode http
    option httplog
    option dontlognull
    option log-health-checks
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:admin123

frontend ollama_frontend
    bind *:8080
    mode http
    option httplog
    
    acl is_chat path_beg /api/chat
    acl is_generate path_beg /api/generate
    
    use_backend ollama_chat if is_chat
    use_backend ollama_generate if is_generate
    default_backend ollama_api

backend ollama_api
    mode http
    balance roundrobin
    option redispatch
    # 移除健康检查，因为 /api/health 似乎不可用
    timeout server 300s
    server ollama1 127.0.0.1:11434

backend ollama_chat
    mode http
    balance roundrobin
    option redispatch
    timeout server 300s
    server ollama1 127.0.0.1:11434

backend ollama_generate
    mode http
    balance roundrobin
    option redispatch
    timeout server 300s
    server ollama1 127.0.0.1:11434
EOL

# Configure sshd for port forwarding
echo "Configuring SSH server..."
sed -i 's/#GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Test HAProxy configuration
echo "Testing HAProxy configuration..."
haproxy -c -f $haproxy_cfg

# Start HAProxy
echo "Starting HAProxy..."
systemctl restart haproxy

# Configure firewall rules
if command -v ufw > /dev/null; then
    echo "Configuring firewall rules..."
    ufw allow ssh
    ufw allow 8080/tcp
    ufw allow 8404/tcp
fi

# Create monitoring script
cat > /usr/local/bin/check_ollama.sh << 'EOF'
#!/bin/bash

echo "=== Ollama Service Status Check ==="

echo -e "\n1. Checking HAProxy status..."
systemctl status haproxy

echo -e "\n2. Checking port 11434 (Ollama)..."
netstat -tlnp | grep 11434

echo -e "\n3. Testing local Ollama connection..."
curl -s http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d '{"model":"llama3-chinese","prompt":"test"}' \
    | head -n 1

echo -e "\n4. Testing HAProxy connection..."
curl -s http://localhost:8080/api/generate \
    -H "Content-Type: application/json" \
    -d '{"model":"llama3-chinese","prompt":"test"}' \
    | head -n 1

echo -e "\n5. Checking HAProxy logs..."
tail -n 10 /var/log/haproxy.log
EOF

chmod +x /usr/local/bin/check_ollama.sh

echo "Setup completed successfully!"
echo "You can check the service status using: /usr/local/bin/check_ollama.sh"