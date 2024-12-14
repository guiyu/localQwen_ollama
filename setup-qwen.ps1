# 检查管理员权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 设置工作目录
$ollamaPath = "D:\ollama"
Set-Location $ollamaPath

# 创建配置和日志目录
$configPath = Join-Path $ollamaPath "config"
$logPath = Join-Path $ollamaPath "logs"
New-Item -ItemType Directory -Path $configPath, $logPath -Force | Out-Null

# 创建Qwen模型配置文件
$modelConfig = @"
FROM qwen:7b-chat

# 系统参数配置
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1
PARAMETER num_ctx 2048

# 系统提示语配置
SYSTEM You are a helpful AI assistant based on Qwen language model. You should provide accurate, informative and relevant responses in the same language as the user's question.

# 设置模型名称
SET name qwen-chat
"@

Set-Content -Path (Join-Path $configPath "qwen.modelfile") -Value $modelConfig -Encoding UTF8

# 下载基础模型
Write-Host "Downloading Qwen model... This may take a while."
& $ollamaPath\ollama.exe pull qwen:7b-chat

# 创建自定义模型
Write-Host "Creating custom model..."
& $ollamaPath\ollama.exe create qwen-chat -f (Join-Path $configPath "qwen.modelfile")

# 创建测试脚本
$testScript = @'
function Test-Model {
    param(
        [string]$Model = "qwen-chat",
        [string]$Prompt = "你好，请做个自我介绍"
    )
    
    $body = @{
        model = $Model
        messages = @(
            @{
                role = "user"
                content = $Prompt
            }
        )
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/chat" `
            -Method Post `
            -Body $body `
            -ContentType "application/json"
        
        Write-Host "Response from $Model`:"
        Write-Host "----------------------------------------"
        Write-Host $response.message.content
        Write-Host "----------------------------------------"
        return $true
    } catch {
        Write-Host "Error testing model $Model`: $($_.Exception.Message)"
        return $false
    }
}

# 测试模型
Write-Host "Testing Qwen model..."
Test-Model
'@

Set-Content -Path (Join-Path $ollamaPath "test-chat.ps1") -Value $testScript

# 创建服务监控脚本
$monitorScript = @'
function Get-OllamaStatus {
    $service = Get-Service -Name "Ollama"
    $port = Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue
    $gpu = nvidia-smi --query-gpu=memory.used,memory.total,temperature.gpu --format=csv,noheader
    
    Write-Host "Ollama Service Status: $($service.Status)"
    Write-Host "Port 11434 Status: $(if($port){'Listening'}else{'Not listening'})"
    Write-Host "GPU Status: $gpu"
    
    # 列出可用模型
    try {
        $models = Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
        Write-Host "`nAvailable Models:"
        $models.models | ForEach-Object {
            Write-Host "- $($_.name) (Size: $([math]::Round($_.size/1GB, 2))GB)"
        }
    } catch {
        Write-Host "Error getting model list: $($_.Exception.Message)"
    }
}

Get-OllamaStatus
'@

Set-Content -Path (Join-Path $ollamaPath "monitor-ollama.ps1") -Value $monitorScript

# 启动服务状态检查
Write-Host "`nChecking service status..."
$service = Get-Service -Name "Ollama"
if ($service.Status -ne "Running") {
    Write-Host "Starting Ollama service..."
    Start-Service -Name "Ollama"
    Start-Sleep -Seconds 5
}

Write-Host "`nSetup complete! Available scripts:"
Write-Host "1. test-chat.ps1    - Test the chat functionality"
Write-Host "2. monitor-ollama.ps1 - Monitor service status"

Write-Host "`nTo test the model, run:"
Write-Host ".\test-chat.ps1"