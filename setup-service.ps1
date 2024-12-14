# 检查管理员权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 设置工作目录
$ollamaPath = "D:\ollama"
Set-Location $ollamaPath

# 清理之前的NSSM文件
Write-Host "Cleaning up previous NSSM installation..."
try {
    # 停止可能正在运行的服务
    $service = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name "Ollama" -Force -ErrorAction SilentlyContinue
        # 给服务一点时间来停止
        Start-Sleep -Seconds 5
    }
    
    # 强制结束任何nssm进程
    Get-Process | Where-Object {$_.Name -like "*nssm*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # 清理旧文件
    if (Test-Path "$ollamaPath\nssm.zip") {
        Remove-Item "$ollamaPath\nssm.zip" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "$ollamaPath\nssm") {
        Remove-Item "$ollamaPath\nssm" -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "Warning: Could not clean up some files. Continuing anyway..."
}

# 下载NSSM
Write-Host "Downloading NSSM..."
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$nssmPath = Join-Path $ollamaPath "nssm.zip"

try {
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmPath
    # 解压到临时目录
    $tempPath = Join-Path $ollamaPath "nssm_temp"
    Expand-Archive -Path $nssmPath -DestinationPath $tempPath -Force
    
    # 创建最终目录
    $nssmFinalPath = Join-Path $ollamaPath "nssm"
    New-Item -ItemType Directory -Path $nssmFinalPath -Force | Out-Null
    
    # 复制文件到最终目录
    Copy-Item -Path "$tempPath\nssm-2.24\win64\*" -Destination $nssmFinalPath -Force
    
    # 清理临时文件
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $nssmPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Failed to download or extract NSSM: $_"
    exit 1
}

# 使用新的NSSM路径
$nssmExe = Join-Path $nssmFinalPath "nssm.exe"

# 检查NSSM是否可用
if (-not (Test-Path $nssmExe)) {
    Write-Host "NSSM executable not found at: $nssmExe"
    exit 1
}

# 检查Ollama服务是否已存在
$serviceExists = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue

if ($serviceExists) {
    Write-Host "Stopping existing Ollama service..."
    Stop-Service -Name "Ollama" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "Removing existing Ollama service..."
    & $nssmExe remove "Ollama" confirm
    Start-Sleep -Seconds 2
}

# 创建新服务
Write-Host "Creating Ollama service..."
$ollamaExe = Join-Path $ollamaPath "ollama.exe"

# 检查Ollama可执行文件是否存在
if (-not (Test-Path $ollamaExe)) {
    Write-Host "Error: Ollama executable not found at: $ollamaExe"
    Write-Host "Please make sure Ollama is properly installed first."
    exit 1
}

# 使用NSSM创建服务
& $nssmExe install "Ollama" $ollamaExe

# 配置服务参数
& $nssmExe set "Ollama" AppParameters "serve"
& $nssmExe set "Ollama" AppDirectory $ollamaPath
& $nssmExe set "Ollama" DisplayName "Ollama AI Service"
& $nssmExe set "Ollama" Description "Ollama AI Local Service"
& $nssmExe set "Ollama" Start "SERVICE_AUTO_START"
& $nssmExe set "Ollama" ObjectName "LocalSystem"

# 设置环境变量
$env = @{
    "GPU_DEVICE"="0"
    "CUDA_VISIBLE_DEVICES"="0"
}

foreach ($key in $env.Keys) {
    & $nssmExe set "Ollama" AppEnvironmentExtra "$key=$($env[$key])"
}

# 设置日志
$logPath = Join-Path $ollamaPath "logs"
New-Item -ItemType Directory -Path $logPath -Force | Out-Null

& $nssmExe set "Ollama" AppStdout (Join-Path $logPath "ollama.log")
& $nssmExe set "Ollama" AppStderr (Join-Path $logPath "ollama.err")
& $nssmExe set "Ollama" AppRotateFiles 1
& $nssmExe set "Ollama" AppRotateOnline 1
& $nssmExe set "Ollama" AppRotateSeconds 86400
& $nssmExe set "Ollama" AppRotateBytes 1048576

# 启动服务
Write-Host "Starting Ollama service..."
Start-Service -Name "Ollama"

# 等待服务启动
Start-Sleep -Seconds 5

# 检查服务状态
$service = Get-Service -Name "Ollama"
if ($service.Status -eq "Running") {
    Write-Host "Ollama service started successfully!"
    
    # 测试服务是否正常响应
    try {
        $testResponse = Invoke-WebRequest -Uri "http://localhost:11434/api/health" -TimeoutSec 5
        if ($testResponse.StatusCode -eq 200) {
            Write-Host "Service health check passed!"
        }
    } catch {
        Write-Host "Warning: Service is running but health check failed. Please check the logs."
    }
} else {
    Write-Host "Warning: Service did not start properly, status: $($service.Status)"
    Write-Host "Checking logs for errors..."
    Get-Content (Join-Path $logPath "ollama.err") -Tail 10
}

Write-Host "`nService Installation Complete!"
Write-Host "----------------------------------------"
Write-Host "Quick Reference Commands:"
Write-Host "1. Check service status: Get-Service Ollama"
Write-Host "2. View logs: Get-Content $logPath\ollama.log -Tail 10"
Write-Host "3. Restart service: Restart-Service Ollama"
Write-Host "----------------------------------------"

# 检查是否已经下载了Qwen模型
Write-Host "Checking for Qwen model..."
$modelPath = Join-Path $ollamaPath "models"
if (!(Test-Path "$modelPath\qwen*")) {
    Write-Host "Would you like to download the Qwen model now? (Y/N)"
    $response = Read-Host
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Downloading Qwen model... This may take a while."
        & $ollamaExe pull "qwen:14b"
    } else {
        Write-Host "You can download the model later using: ollama pull qwen:14b"
    }
}

# 创建测试脚本
$testScript = @'
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/chat" -Method Post -Body (@{
        model = "qwen:14b"
        messages = @(
            @{
                role = "user"
                content = "Hello, are you working?"
            }
        )
    } | ConvertTo-Json) -ContentType "application/json"
    
    Write-Host "Test Response:"
    Write-Host $response.message.content
} catch {
    Write-Host "Error testing the API: $_"
}
'@

Set-Content -Path (Join-Path $ollamaPath "test-api.ps1") -Value $testScript

Write-Host "`nSetup complete! You can test the API using the test-api.ps1 script."