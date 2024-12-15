@echo off
setlocal enabledelayedexpansion

:: 设置根目录
set "OLLAMA_ROOT=D:\workspaces\localQwen_ollama\ollama-server"

echo Checking environment...
echo =====================

:: 检查目录结构
echo Checking directories...
for %%d in (
    "bin"
    "models\qwen"
    "configs"
    "logs\server"
    "scripts\utils"
    "scripts\install"
) do (
    if not exist "%OLLAMA_ROOT%\%%d" (
        echo Error: Directory %%d does not exist!
        exit /b 1
    )
)

:: 检查 Python 环境
echo.
echo Checking Python...
python --version > nul 2>&1
if %errorlevel% equ 0 (
    echo Python: Installed
    python -c "import sys; print(f'Version: {sys.version}')"
) else (
    echo Python: Not found
    exit /b 1
)

:: 检查 CUDA
echo.
echo Checking CUDA...
nvidia-smi > nul 2>&1
if %errorlevel% equ 0 (
    echo CUDA: Available
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
) else (
    echo CUDA: Not available
    exit /b 1
)

:: 检查必要文件
echo.
echo Checking required files...
if exist "%OLLAMA_ROOT%\bin\ollama.exe" (
    echo Ollama executable: Found
) else (
    echo Ollama executable: Not found
    echo Please place ollama.exe in the bin directory
    exit /b 1
)

echo.
echo Environment check complete.
exit /b 0