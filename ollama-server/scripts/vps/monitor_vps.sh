#!/bin/bash

# 监控配置
LOG_DIR="/var/log/ollama-monitor"
ALERT_EMAIL="admin@yourdomain.com"
MAX_CONNECTIONS=1000
MAX_CPU_USAGE=80
MAX_MEMORY_USAGE=80

mkdir -p $LOG_DIR

# 监控HAProxy状态
check_haproxy() {
    if ! systemctl is-active --quiet haproxy; then
        echo "HAProxy is down!" | mail -s "Alert: HAProxy Down" $ALERT_EMAIL
        systemctl restart haproxy
    fi
}

# 监控连接数
check_connections() {
    CONN_COUNT=$(netstat -an | grep :443 | grep ESTABLISHED | wc -l)
    if [ $CONN_COUNT -gt $MAX_CONNECTIONS ]; then
        echo "Too many connections: $CONN_COUNT" | mail -s "Alert: High Connection Count" $ALERT_EMAIL
    fi
}

# 监控系统资源
check_system_resources() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
    MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
    
    if [ $CPU_USAGE -gt $MAX_CPU_USAGE ]; then
        echo "High CPU usage: $CPU_USAGE%" | mail -s "Alert: High CPU Usage" $ALERT_EMAIL
    fi
    
    if [ $MEMORY_USAGE -gt $MAX_MEMORY_USAGE ]; then
        echo "High memory usage: $MEMORY_USAGE%" | mail -s "Alert: High Memory Usage" $ALERT_EMAIL
    fi
}

# 主循环
while true; do
    check_haproxy
    check_connections
    check_system_resources
    sleep 60
done