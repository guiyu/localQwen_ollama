@echo off
setlocal enabledelayedexpansion

:: 设置根目录
set "OLLAMA_ROOT=D:\workspaces\localQwen_ollama\ollama-server"
cd /d "%OLLAMA_ROOT%"

echo Starting full installation...
echo Root directory: %OLLAMA_ROOT%

:: 创建必要的目录结构
echo Creating directory structure...
for %%d in (
    "bin"
    "models\qwen"
    "configs"
    "logs\server"
    "logs\models"
    "cache\embeddings"
    "cache\responses"
    "data\status"
    "data\metrics"
    "tools\monitoring"
    "tools\maintenance"
) do (
    if not exist "%OLLAMA_ROOT%\%%d" (
        echo Creating directory: %%d
        mkdir "%OLLAMA_ROOT%\%%d"
    )
)

:: 1. 检查环境
echo Checking environment...
call "%OLLAMA_ROOT%\scripts\utils\check_env.bat"
if %errorlevel% neq 0 (
    echo Environment check failed!
    exit /b 1
)

:: 2. 设置服务
echo Setting up service...
call "%OLLAMA_ROOT%\scripts\install\setup_service.bat"
if %errorlevel% neq 0 (
    echo Service setup failed!
    exit /b 1
)

:: 3. 安装模型
echo Installing model...
call "%OLLAMA_ROOT%\scripts\install\setup_model.bat"
if %errorlevel% neq 0 (
    echo Model setup failed!
    exit /b 1
)

echo Installation completed successfully!
pause