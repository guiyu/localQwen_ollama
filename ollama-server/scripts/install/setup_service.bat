@echo off
setlocal enabledelayedexpansion

echo Setting up Ollama Windows service...

:: 下载 NSSM
if not exist "%OLLAMA_ROOT%\tools\nssm.exe" (
    echo Downloading NSSM...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile '%TEMP%\nssm.zip'}"
    powershell -Command "& {Expand-Archive -Path '%TEMP%\nssm.zip' -DestinationPath '%TEMP%\nssm'}"
    copy "%TEMP%\nssm\nssm-2.24\win64\nssm.exe" "%OLLAMA_ROOT%\tools\"
    del /Q "%TEMP%\nssm.zip"
    rd /S /Q "%TEMP%\nssm"
)

:: 安装服务
"%OLLAMA_ROOT%\tools\nssm.exe" install OllamaService "%OLLAMA_ROOT%\bin\ollama.exe"
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService AppParameters "serve"
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService DisplayName "Ollama AI Service"
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService Description "Ollama AI Local Service"
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService Start SERVICE_AUTO_START
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService ObjectName LocalSystem

:: 设置环境变量
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService AppEnvironmentExtra "GPU_DEVICE=0" "CUDA_VISIBLE_DEVICES=0"

:: 设置日志
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService AppStdout "%OLLAMA_ROOT%\logs\server\ollama.log"
"%OLLAMA_ROOT%\tools\nssm.exe" set OllamaService AppStderr "%OLLAMA_ROOT%\logs\server\error.log"

:: 启动服务
net start OllamaService

echo Service setup complete!