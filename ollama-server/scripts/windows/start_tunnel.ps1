param(
    [string]$VpsIp = "192.3.59.148",
    [string]$VpsUser = "root",
    [int]$LocalPort = 11434,
    [int]$RemotePort = 11434
)

# 启动SSH反向隧道
while ($true) {
    Write-Host "Starting SSH tunnel..."
    ssh -N -R $RemotePort`:localhost:$LocalPort $VpsUser@$VpsIp
    
    Write-Host "Tunnel disconnected. Reconnecting in 5 seconds..."
    Start-Sleep -Seconds 5
}