# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required. Requesting elevation..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Setup logging
$logPath = "D:\workspaces\localQwen_ollama\ollama-server\logs\setup"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}
$logFile = Join-Path $logPath "setup.log"
Start-Transcript -Path $logFile -Append

try {
    # Function to find Git Bash
    function Find-GitBash {
        # Get Git command path
        $gitCmd = (Get-Command git -ErrorAction SilentlyContinue).Source
        if ($gitCmd) {
            Write-Host "Found git at: $gitCmd"
            $gitRoot = Split-Path (Split-Path $gitCmd)
            $gitBashPath = Join-Path $gitRoot "bin\bash.exe"
            if (Test-Path $gitBashPath) {
                return $gitBashPath
            }
        }
        
        $possiblePaths = @(
            "D:\Program Files\Git\bin\bash.exe",
            "${env:ProgramFiles}\Git\bin\bash.exe",
            "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
            "${env:LocalAppData}\Programs\Git\bin\bash.exe",
            "C:\Git\bin\bash.exe"
        )
        
        foreach ($path in $possiblePaths) {
            Write-Host "Checking path: $path"
            if (Test-Path $path) {
                return $path
            }
        }
        
        return $null
    }

    # Find Git Bash
    $bashPath = Find-GitBash
    if (-not $bashPath) {
        throw "Git Bash not found. Please ensure Git is properly installed and try again. Current Git Path: $((Get-Command git -ErrorAction SilentlyContinue).Source)"
    }

    Write-Host "Found Git Bash at: $bashPath"
    $gitRoot = Split-Path (Split-Path $bashPath)
    Write-Host "Git Root: $gitRoot"

    # Verify NSSM
    $nssm = "D:\workspaces\localQwen_ollama\ollama-server\tools\nssm.exe"
    if (-not (Test-Path $nssm)) {
        throw "NSSM tool not found at: $nssm"
    }
    Write-Host "Found NSSM at: $nssm"

    # Create tunnel startup script
    $tunnelScript = @'
#!/bin/bash
VPS_IP="192.3.59.148"
VPS_USER="root"
LOCAL_PORT=11434
REMOTE_PORT=11434

echo "Starting SSH tunnel service at $(date)"
echo "Connecting to: $VPS_USER@$VPS_IP"

while true; do
    echo "Starting SSH tunnel..."
    ssh -vv -N -R $REMOTE_PORT:localhost:$LOCAL_PORT $VPS_USER@$VPS_IP
    echo "Tunnel disconnected at $(date). Reconnecting in 5 seconds..."
    sleep 5
done
'@

    $tunnelScriptPath = "D:\workspaces\localQwen_ollama\ollama-server\scripts\windows\start_tunnel.sh"
    Write-Host "Creating tunnel script at: $tunnelScriptPath"
    $tunnelScript | Out-File -FilePath $tunnelScriptPath -Encoding ASCII

    # Create batch file to run tunnel
    $batchScript = @"
@echo off
echo Starting Ollama Tunnel Service at %DATE% %TIME%
SET PATH=$gitRoot\bin;$gitRoot\usr\bin;%PATH%
"$bashPath" --login -i -c "bash '/d/workspaces/localQwen_ollama/ollama-server/scripts/windows/start_tunnel.sh'" > "D:\workspaces\localQwen_ollama\ollama-server\logs\tunnel.log" 2>&1
"@

    $batchPath = "D:\workspaces\localQwen_ollama\ollama-server\scripts\windows\run_tunnel.bat"
    Write-Host "Creating batch file at: $batchPath"
    $batchScript | Out-File -FilePath $batchPath -Encoding ASCII

    # Remove existing service if any
    Write-Host "Removing existing service if any..."
    & $nssm stop "OllamaTunnel" 2>$null
    Start-Sleep -Seconds 2
    & $nssm remove "OllamaTunnel" confirm 2>$null
    Start-Sleep -Seconds 2

    # Create and configure service
    Write-Host "Creating new service..."
    $result = & $nssm install "OllamaTunnel" $batchPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create service: $result"
    }

    Write-Host "Configuring service..."
    & $nssm set "OllamaTunnel" DisplayName "Ollama SSH Tunnel Service"
    & $nssm set "OllamaTunnel" Description "Maintains SSH tunnel for Ollama service"
    & $nssm set "OllamaTunnel" AppDirectory "D:\workspaces\localQwen_ollama\ollama-server\scripts\windows"
    & $nssm set "OllamaTunnel" AppStdout "D:\workspaces\localQwen_ollama\ollama-server\logs\tunnel.log"
    & $nssm set "OllamaTunnel" AppStderr "D:\workspaces\localQwen_ollama\ollama-server\logs\tunnel_error.log"
    & $nssm set "OllamaTunnel" Start SERVICE_AUTO_START

    Write-Host "Service created successfully!"
    Write-Host "Please follow these steps:"
    Write-Host "1. Edit start_tunnel.sh and set correct VPS_IP and VPS_USER"
    Write-Host "2. Open Git Bash and run 'ssh-keygen -t rsa' to generate SSH keys"
    Write-Host "3. Run 'ssh-copy-id root@YOUR_VPS_IP' to copy keys to VPS"
    Write-Host "4. Start the service using: net start OllamaTunnel"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
} finally {
    Stop-Transcript
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')