@echo off
echo Setting up Conda environment for Ollama testing...

:: 设置环境变量
set OLLAMA_ROOT=D:\ollama-server
set OLLAMA_MODELS=%OLLAMA_ROOT%\models
set OLLAMA_CACHE=%OLLAMA_ROOT%\cache
set PATH=%OLLAMA_ROOT%\bin;%PATH%

:: 检查是否安装了 Conda
where conda >nul 2>nul
if %errorlevel% neq 0 (
    echo Conda not found. Please install Miniconda or Anaconda first.
    pause
    exit /b
)

:: 创建新的 Conda 环境
echo Creating new Conda environment: ollama_test
conda create -n ollama_test python=3.9 -y

:: 激活环境并安装依赖
call conda activate ollama_test
pip install -r requirements.txt

echo.
echo Environment setup complete!
echo To activate the environment, use: conda activate ollama_test
pause