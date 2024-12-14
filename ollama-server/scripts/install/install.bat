@echo off
setlocal

:: 设置环境变量
set OLLAMA_ROOT=D:\ollama-server
set PATH=%OLLAMA_ROOT%\bin;%PATH%

:: 创建必要的目录结构
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
) do (
    mkdir "%OLLAMA_ROOT%\%%d" 2>nul
)

:: 复制文件
copy "ollama.exe" "%OLLAMA_ROOT%\bin\"
copy "configs\server.json" "%OLLAMA_ROOT%\configs\"
copy "models\qwen\modelfile" "%OLLAMA_ROOT%\models\qwen\"

:: 运行模型安装
call "%OLLAMA_ROOT%\scripts\install\setup_model.bat"

echo Installation complete!