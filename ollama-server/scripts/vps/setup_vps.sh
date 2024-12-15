#!/bin/bash

# 设置错误处理
set -e
log_file="/var/log/ollama_setup.log"
exec 1> >(tee -a "$log_file")
exec 2>&1

echo "Starting Ollama VPS setup..."

# 检查必要软件
echo "Checking and installing required packages..."
apt-get update
apt-get install -y haproxy socat openssh-server

# 配置SSH允许反向隧道
echo "Configuring SSH for reverse tunnel..."
cat >> /etc/ssh/sshd_config << EOF
GatewayPorts yes
AllowTcpForwarding yes
EOF

# 重启SSH服务
systemctl restart sshd

# 配置HAProxy
echo "Configuring HAProxy..."
haproxy_cfg="/etc/haproxy/haproxy.cfg"
cp $haproxy_cfg "${haproxy_cfg}.backup"

# 创建配置文件
cat > $haproxy_cfg << 'EOL'
global
    log /dev/log local0
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
    
    option forwardfor
    
    acl is_chat path_beg /api/chat
    acl is_generate path_beg /api/generate
    
    stick-table type ip size 100k expire 30s store conn_cur,conn_rate(3s),http_req_rate(10s)
    http-request track-sc0 src
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 20 }
    
    use_backend ollama_chat if is_chat
    use_backend ollama_generate if is_generate
    default_backend ollama_api

backend ollama_api
    mode http
    balance roundrobin
    option httpchk GET /api/health
    http-check expect status 200
    server ollama1 127.0.0.1:11434 check inter 2000 rise 2 fall 3

backend ollama_chat
    mode http
    balance roundrobin
    option httpchk GET /api/health
    http-check expect status 200
    timeout server 300s
    server ollama1 127.0.0.1:11434 check maxconn 100

backend ollama_generate
    mode http
    balance roundrobin
    option httpchk GET /api/health
    http-check expect status 200
    timeout server 300s
    server ollama1 127.0.0.1:11434 check maxconn 100
EOL

# 测试HAProxy配置
echo "Testing HAProxy configuration..."
haproxy -c -f $haproxy_cfg

# 启动HAProxy
echo "Starting HAProxy..."
systemctl restart haproxy

# 设置防火墙规则
if command -v ufw > /dev/null; then
    echo "Configuring firewall rules..."
    ufw allow ssh
    ufw allow 8080/tcp
    ufw allow 8404/tcp
    ufw allow 11434/tcp
fi

# 创建隧道状态监控脚本
cat > /usr/local/bin/check-tunnel.sh << 'EOF'
#!/bin/bash

check_tunnel() {
    if netstat -an | grep "LISTEN" | grep -q ":11434"; then
        echo "Tunnel is UP"
        return 0
    else
        echo "Tunnel is DOWN"
        return 1
    fi
}

echo "Checking tunnel status..."
check_tunnel
EOF

chmod +x /usr/local/bin/check-tunnel.sh

echo "Setup completed successfully!"
echo "Please run the following steps on Windows server:"
echo "1. Install OpenSSH Server"
echo "2. Run start_tunnel.ps1 script with your VPS IP"
echo "3. The service will be available at http://YOUR_VPS_IP:8080"