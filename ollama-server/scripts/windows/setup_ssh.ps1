# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required. Requesting elevation..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to find Git Bash
function Find-GitBash {
    # Get Git command path
    $gitCmd = (Get-Command git -ErrorAction SilentlyContinue).Source
    if ($gitCmd) {
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
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

# Find Git Bash
$bashPath = Find-GitBash
if (-not $bashPath) {
    Write-Host "Error: Git Bash not found. Please ensure Git is properly installed and try again."
    Write-Host "Current Git Path: $((Get-Command git -ErrorAction SilentlyContinue).Source)"
    exit 1
}

Write-Host "Found Git Bash at: $bashPath"

# Create tunnel startup script
$tunnelScript = @'
#!/bin/bash
VPS_IP="YOUR_VPS_IP"
VPS_USER="root"
LOCAL_PORT=11434
REMOTE_PORT=11434

while true; do
    echo "Starting SSH tunnel..."
    ssh -N -R $REMOTE_PORT:localhost:$LOCAL_PORT $VPS_USER@$VPS_IP
    echo "Tunnel disconnected. Reconnecting in 5 seconds..."
    sleep 5
done
'@

# Save tunnel script
$tunnelScriptPath = "D:\workspaces\localQwen_ollama\ollama-server\scripts\windows\start_tunnel.sh"
$tunnelScript | Out-File -FilePath $tunnelScriptPath -Encoding ASCII

# Create batch file to run tunnel
$gitRoot = Split-Path (Split-Path $bashPath)
$batchScript = @"
@echo off
SET PATH=$gitRoot\bin;$gitRoot\usr\bin;%PATH%
"$bashPath" --login -i -c "bash '/d/workspaces/localQwen_ollama/ollama-server/scripts/windows/start_tunnel.sh'"
"@

$batchPath = "D:\workspaces\localQwen_ollama\ollama-server\scripts\windows\run_tunnel.bat"
$batchScript | Out-File -FilePath $batchPath -Encoding ASCII

# Create Windows service
$nssm = "D:\workspaces\localQwen_ollama\ollama-server\tools\nssm.exe"
if (-not (Test-Path $nssm)) {
    Write-Host "Error: NSSM tool not found at: $nssm"
    exit 1
}

# Remove existing service if any
& $nssm remove "OllamaTunnel" confirm 2>$null

# Create and configure service
& $nssm install "OllamaTunnel" $batchPath
& $nssm set "OllamaTunnel" DisplayName "Ollama SSH Tunnel Service"
& $nssm set "OllamaTunnel" Description "Maintains SSH tunnel for Ollama service"
& $nssm set "OllamaTunnel" AppDirectory "D:\workspaces\localQwen_ollama\ollama-server\scripts\windows"
& $nssm set "OllamaTunnel" Start SERVICE_AUTO_START

Write-Host "SSH tunnel service has been created!"
Write-Host "Please follow these steps:"
Write-Host "1. Edit start_tunnel.sh and set correct VPS_IP and VPS_USER"
Write-Host "2. Open Git Bash and run 'ssh-keygen -t rsa' to generate SSH keys"
Write-Host "3. Run 'ssh-copy-id root@YOUR_VPS_IP' to copy keys to VPS"
Write-Host "4. Start the service: Start-Service OllamaTunnel"
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')