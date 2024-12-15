@echo off
setlocal enabledelayedexpansion

set "OLLAMA_ROOT=D:\workspaces\localQwen_ollama\ollama-server"

echo Checking environment...

:: 检查 Python
python --version > nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found!
    exit /b 1
)

:: 检查 Ollama 服务
curl -s http://localhost:11434/api/tags > nul
if %errorlevel% neq 0 (
    echo Ollama service not running!
    exit /b 1
)

:: 检查模型
curl -s http://localhost:11434/api/tags | findstr "qwen:7b-chat" > nul
if %errorlevel% neq 0 (
    echo Model qwen:7b-chat not found!
    exit /b 1
)

echo Environment check passed.
exit /b 0