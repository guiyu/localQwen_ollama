@echo off
setlocal enabledelayedexpansion

:: 设置环境变量
set OLLAMA_ROOT=D:\ollama-server
set MODELS_DIR=%OLLAMA_ROOT%\models
set CONFIG_DIR=%OLLAMA_ROOT%\configs
set LOG_DIR=%OLLAMA_ROOT%\logs\models

echo Setting up Qwen model...

:: 检查Ollama服务状态
sc query OllamaService > nul
if %errorlevel% neq 0 (
    echo Starting Ollama service...
    net start OllamaService
    timeout /t 5
)

:: 下载并配置模型
echo Downloading Qwen model...
"%OLLAMA_ROOT%\bin\ollama.exe" pull qwen:7b-chat

:: 应用自定义配置
echo Applying custom configuration...
"%OLLAMA_ROOT%\bin\ollama.exe" create qwen-chat -f "%MODELS_DIR%\qwen\modelfile"

:: 验证模型安装
echo Verifying model installation...
"%OLLAMA_ROOT%\bin\ollama.exe" list

:: 测试模型
echo Testing model...
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen-chat\",\"prompt\":\"Hello, are you working?\"}" ^
  http://localhost:11434/api/generate

:: 检查是否成功
if %errorlevel% equ 0 (
    echo Model setup completed successfully!
) else (
    echo Error: Model setup failed!
    exit /b 1
)

:: 创建模型信息文件
echo {^
    "name": "qwen-chat",^
    "base_model": "qwen:7b-chat",^
    "created_at": "%date% %time%"^
} > "%MODELS_DIR%\qwen\info.json"

echo Setup complete! Model is ready for use.