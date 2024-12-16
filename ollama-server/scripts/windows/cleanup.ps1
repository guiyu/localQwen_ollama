# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Starting cleanup..."

# 1. Stop service
Write-Host "Stopping services..."
Stop-Service OllamaService -ErrorAction SilentlyContinue
& $nssmExe remove OllamaService confirm 2>$null

# 2. Kill processes
Write-Host "Killing processes..."
$processes = @(Get-WmiObject Win32_Process | Where-Object { $_.Name -match 'ollama' })
foreach ($process in $processes) {
    Write-Host "Stopping process: $($process.Name) (PID: $($process.ProcessId))"
    $process.Terminate()
}

# 3. Free up port
Write-Host "Freeing up port 11434..."
$netstat = netstat -ano | findstr ":11434"
if ($netstat) {
    $netstat -split ' ' | ForEach-Object {
        if ($_ -match '^\d+$') {
            Write-Host "Killing process with PID: $_"
            taskkill /F /PID $_ 2>$null
        }
    }
}

# 4. Clean up logs
Write-Host "Cleaning up logs..."
$logPath = "D:\workspaces\localQwen_ollama\ollama-server\logs"
if (Test-Path $logPath) {
    Remove-Item "$logPath\*" -Force -Recurse
}

Start-Sleep -Seconds 5

Write-Host "Cleanup completed"