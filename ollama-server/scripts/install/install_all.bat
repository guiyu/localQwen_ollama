@echo off
setlocal enabledelayedexpansion

echo Starting full installation...

:: 1. 检查环境
call "%OLLAMA_ROOT%\scripts\utils\check_env.bat"
if %errorlevel% neq 0 (
    echo Environment check failed!
    exit /b 1
)

:: 2. 设置服务
call "%OLLAMA_ROOT%\scripts\install\setup_service.bat"
if %errorlevel% neq 0 (
    echo Service setup failed!
    exit /b 1
)

:: 3. 安装模型
call "%OLLAMA_ROOT%\scripts\install\setup_model.bat"
if %errorlevel% neq 0 (
    echo Model setup failed!
    exit /b 1
)

echo Installation completed successfully!