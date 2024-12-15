# 安装NSSM服务管理工具
$nssmPath = "D:\workspaces\localQwen_ollama\ollama-server\tools\nssm.exe"

# 创建隧道服务
& $nssmPath install "OllamaTunnel" "powershell.exe"
& $nssmPath set "OllamaTunnel" AppParameters "-ExecutionPolicy Bypass -File `"D:\workspaces\localQwen_ollama\ollama-server\scripts\windows\start_tunnel.ps1`""
& $nssmPath set "OllamaTunnel" AppDirectory "D:\workspaces\localQwen_ollama\ollama-server"
& $nssmPath set "OllamaTunnel" DisplayName "Ollama SSH Tunnel Service"
& $nssmPath set "OllamaTunnel" Description "Maintains SSH tunnel for Ollama service"
& $nssmPath set "OllamaTunnel" Start SERVICE_AUTO_START

# 启动服务
Start-Service OllamaTunnel