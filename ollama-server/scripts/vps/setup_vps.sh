#!/bin/bash

# 安装必要的软件包
apt-get update
apt-get install -y haproxy nginx certbot python3-certbot-nginx socat

# 配置HAProxy
cat > /etc/haproxy/haproxy.cfg << EOF
$(cat ../../configs/haproxy.cfg)
EOF

# 生成SSL证书
certbot certonly --standalone -d your-domain.com --non-interactive --agree-tos --email your-email@domain.com

# 合并证书给HAProxy使用
cat /etc/letsencrypt/live/your-domain.com/fullchain.pem \
    /etc/letsencrypt/live/your-domain.com/privkey.pem > /etc/ssl/private/ollama.pem

# 设置证书权限
chmod 600 /etc/ssl/private/ollama.pem

# 启动HAProxy
systemctl enable haproxy
systemctl restart haproxy

# 配置自动更新证书
cat > /etc/cron.d/certbot-renew << EOF
0 0 * * * root certbot renew --quiet --post-hook "systemctl reload haproxy"
EOF