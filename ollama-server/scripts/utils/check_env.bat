@echo off
setlocal enabledelayedexpansion

echo Checking environment...
echo =====================

:: 检查 Python 环境
python --version > nul 2>&1
if %errorlevel% equ 0 (
    echo Python: Installed
    python -c "import sys; print(f'Version: {sys.version}')"
) else (
    echo Python: Not found
    exit /b 1
)

:: 检查必要的 Python 包
echo.
echo Checking Python packages...
python -c "import pkg_resources; [print(f'{p.key}: {p.version}') for p in pkg_resources.working_set if p.key in ['pandas', 'matplotlib', 'seaborn', 'numpy']]"

:: 检查 CUDA
nvidia-smi > nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo CUDA: Available
    for /f "tokens=* usebackq" %%i in (`nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader`) do (
        echo GPU: %%i
    )
) else (
    echo.
    echo CUDA: Not available
)

:: 检查 Ollama
"%OLLAMA_ROOT%\bin\ollama.exe" version > nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Ollama: Installed
    "%OLLAMA_ROOT%\bin\ollama.exe" version
) else (
    echo.
    echo Ollama: Not installed
    exit /b 1
)

echo.
echo Environment check complete.