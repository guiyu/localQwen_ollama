# Ollama Windows本地部署方案

## 项目介绍
本项目实现了基于Windows的Ollama本地部署方案，通过VPS实现公网访问。主要特点：
- Windows本地运行Ollama服务
- VPS提供反向代理和公网访问能力
- SSH隧道实现内网穿透
- HAProxy负载均衡支持

## 系统要求

### Windows服务器
- Windows 10/11
- 16GB+ RAM
- NVIDIA GPU (推荐RTX 4070或更高)
- Git Bash
- PowerShell 5.0+

### VPS服务器
- Ubuntu 22.04 LTS
- 2GB+ RAM
- 公网IP

## 目录结构
D:\workspaces\localQwen_ollama
├── ollama-server
├── bin
│   ├── ollama.exe
│   └── start_ollama.bat
├── models
│   └── qwen
│       └── modelfile
├── configs
│   ├── server.json
│   └── haproxy.cfg
├── logs
│   ├── ollama.log
│   ├── service_out.log
│   └── service_err.log
├── scripts
│   ├── windows
│   │   ├── setup_service.ps1
│   │   ├── cleanup.ps1
│   │   └── start_tunnel.sh
│   └── vps
│       └── setup_vps.sh
└── tools
└── nssm.exe
## 部署步骤

### Windows端部署

1. 环境准备
```powershell
# 以管理员权限运行PowerShell
cd D:\workspaces\localQwen_ollama\ollama-server\scripts\windows
2. 清理环境（如果需要）
.\cleanup.ps1
3. 安装和配置服务
.\setup_service.ps1
4. 启动SSH隧道（在Git Bash中运行）
./start_tunnel.sh

### VPS端部署

1. 安装必要组件
apt-get update && apt-get install -y haproxy

2. 部署配置
cd ~/localQwen_ollama/ollama-server/scripts/vps
chmod +x setup_vps.sh
./setup_vps.sh

### 验证部署
#### Windows端验证
Get-Service OllamaService

curl http://localhost:11434/api/generate `
    -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body '{"model":"llama3-chinese","prompt":"你好"}'

#### VPS端验证
systemctl status haproxy

curl http://localhost:8080/api/generate \
    -H "Content-Type: application/json" \
    -d '{"model":"llama3-chinese","prompt":"你好"}'

##API访问说明
###基础API

端点：http://YOUR_VPS_IP:8080/api/
生成接口：/api/generate
聊天接口：/api/chat

###HAProxy监控

统计页面：http://YOUR_VPS_IP:8404/stats
默认凭据：

用户名：admin
密码：admin123



##维护指南
###Windows端维护
powershellCopy# 重启服务
Restart-Service OllamaService

查看日志
Get-Content "D:\workspaces\localQwen_ollama\ollama-server\logs\ollama.log" -Tail 100

重建SSH隧道
./start_tunnel.sh
VPS端维护
bashCopy# 重启HAProxy
systemctl restart haproxy

查看日志
tail -f /var/log/haproxy.log

运行状态检查
/usr/local/bin/check_ollama.sh
故障排除

###服务启动失败

检查日志：Get-Content D:\workspaces\localQwen_ollama\ollama-server\logs\ollama.log
运行清理脚本：cleanup.ps1
重新安装服务：setup_service.ps1


###API访问失败

检查SSH隧道状态
验证本地服务是否正常运行
检查HAProxy配置和状态


##性能问题

检查GPU使用情况
监控内存占用
查看HAProxy统计信息



##安全建议

###基础安全

修改HAProxy统计页面的默认密码
配置防火墙只允许必要的端口访问
使用强密码和密钥认证


##访问控制

限制API访问IP
配置请求速率限制
监控异常访问


##日志管理

定期轮转日志
监控错误日志
保存关键操作日志



#更新日志
2024-12-16

完善HAProxy配置
移除不必要的健康检查
优化SSH隧道配置
添加服务监控脚本
完善部署文档