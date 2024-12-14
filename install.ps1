# 检查是否以管理员身份运行
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 检查是否已安装 WSL
$wslCheck = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL 未安装或未正确配置，请先运行 install-wsl.ps1 脚本"
    exit 1
}

# 下载 Ollama Windows 安装包
Write-Host "下载 Ollama..."
$ollamaUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
$downloadPath = "D:\ollama\ollama.zip"
Invoke-WebRequest -Uri $ollamaUrl -OutFile $downloadPath

# 解压安装包
Write-Host "解压 Ollama..."
Expand-Archive -Path $downloadPath -DestinationPath "D:\ollama" -Force

# 创建配置文件
$configContent = @"
{
    "gpu": true,
    "host": "0.0.0.0",
    "port": 11434
}
"@
Set-Content -Path "D:\ollama\config.json" -Value $configContent

Write-Host "Ollama 安装完成！"
Write-Host "请运行 setup-service.ps1 来设置 Ollama 服务。"