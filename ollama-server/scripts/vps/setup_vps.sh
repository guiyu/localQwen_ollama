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
apt-get install -y haproxy socat

# 检查端口占用
check_port() {
    local port=$1
    if lsof -i :$port > /dev/null; then
        echo "Port $port is in use. Attempting to free it..."
        fuser -k $port/tcp
        sleep 2
    fi
}

check_port 8080
check_port 8404

# 配置HAProxy
echo "Configuring HAProxy..."
haproxy_cfg="/etc/haproxy/haproxy.cfg"
cp $haproxy_cfg "${haproxy_cfg}.backup"

# 复制新的配置文件
cp ../../configs/haproxy.cfg $haproxy_cfg

# 测试HAProxy配置
echo "Testing HAProxy configuration..."
haproxy -c -f $haproxy_cfg

# 启动HAProxy
echo "Starting HAProxy..."
systemctl restart haproxy

# 验证HAProxy是否正在运行
if ! systemctl is-active --quiet haproxy; then
    echo "HAProxy failed to start. Checking logs..."
    journalctl -xe -u haproxy
    exit 1
fi

# 设置防火墙规则
if command -v ufw > /dev/null; then
    echo "Configuring firewall rules..."
    ufw allow 8080/tcp
    ufw allow 8404/tcp
fi

echo "Setup completed successfully!"
echo "You can access:"
echo "1. API service at http://YOUR_IP:8080"
echo "2. Statistics page at http://YOUR_IP:8404/stats (admin/admin123)"

# 创建一个简单的测试脚本
cat > /usr/local/bin/test-ollama.sh << 'EOF'
#!/bin/bash
echo "Testing Ollama API..."
curl -X POST http://localhost:8080/api/generate \
    -H "Content-Type: application/json" \
    -d '{"model": "qwen:7b-chat", "prompt": "Hello, how are you?"}'
EOF

chmod +x /usr/local/bin/test-ollama.sh

echo "Test script created at /usr/local/bin/test-ollama.sh"