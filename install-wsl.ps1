# 必须以管理员权限运行
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 启用 Windows 功能
Write-Host "正在启用必要的Windows功能..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 下载 WSL2 内核更新包
Write-Host "下载 WSL2 内核更新包..."
$wslUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdatePath = "D:\ollama\wsl_update_x64.msi"
Invoke-WebRequest -Uri $wslUrl -OutFile $wslUpdatePath

# 安装 WSL2 内核更新包
Write-Host "安装 WSL2 内核更新包..."
Start-Process msiexec.exe -ArgumentList "/i `"$wslUpdatePath`" /quiet" -Wait

Write-Host "WSL2 安装完成！请重启计算机后继续安装 Ollama。"
Write-Host "重启后，请运行 install.ps1 脚本继续安装。"

# 提示用户重启
$restart = Read-Host "是否现在重启计算机？(Y/N)"
if ($restart -eq 'Y' -or $restart -eq 'y') {
    Restart-Computer -Force
}