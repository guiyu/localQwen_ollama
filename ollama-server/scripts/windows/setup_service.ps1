# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required. Requesting elevation..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define paths
$rootPath = "D:\workspaces\localQwen_ollama\ollama-server"
$binPath = Join-Path $rootPath "bin"
$modelPath = Join-Path $rootPath "models"
$logPath = Join-Path $rootPath "logs"
$ollamaExe = Join-Path $binPath "ollama.exe"
$nssmExe = Join-Path $rootPath "tools\nssm.exe"

# Ensure all directories exist
@($binPath, $modelPath, $logPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "Created directory: $_"
    }
}

# Remove existing service
Write-Host "Removing existing service..."
Stop-Service OllamaService -ErrorAction SilentlyContinue
& $nssmExe remove OllamaService confirm 2>$null
Start-Sleep -Seconds 2

# Create wrapper script for the service
$wrapperScript = @"
@echo off
echo Starting Ollama Service at %date% %time% > "$logPath\service_start.log"
set OLLAMA_MODELS=$modelPath
cd /d "$binPath"
"$ollamaExe" serve >> "$logPath\ollama.log" 2>&1
"@

$wrapperPath = Join-Path $binPath "ollama_service.bat"
Set-Content -Path $wrapperPath -Value $wrapperScript -Encoding ASCII
Write-Host "Created wrapper script: $wrapperPath"

Write-Host "Creating service..."
try {
    # Install service
    $result = & $nssmExe install OllamaService $wrapperPath
    Write-Host "Service installation result: $result"

    # Configure service
    & $nssmExe set OllamaService DisplayName "Ollama AI Service"
    & $nssmExe set OllamaService Description "Local Ollama AI Service"
    & $nssmExe set OllamaService AppDirectory $binPath
    & $nssmExe set OllamaService ObjectName "LocalSystem"
    & $nssmExe set OllamaService Start SERVICE_AUTO_START
    & $nssmExe set OllamaService AppStdout "$logPath\service_out.log"
    & $nssmExe set OllamaService AppStderr "$logPath\service_err.log"

    Write-Host "Service configured successfully"

    # Start service
    Write-Host "Starting service..."
    Start-Service OllamaService
    Start-Sleep -Seconds 10

    # Check service status
    $service = Get-Service OllamaService
    Write-Host "Service status: $($service.Status)"
}
catch {
    Write-Host "Error during service setup: $_"
    Write-Host "Error details: $($_.Exception.Message)"
    exit 1
}

Write-Host "Setup process completed"