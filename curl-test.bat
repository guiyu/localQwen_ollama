@echo off
echo Testing Ollama API...
echo.

:: 测试 generate API
echo Testing /api/generate endpoint...
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\": \"qwen:7b-chat\", \"prompt\": \"Say hi!\"}" ^
  http://localhost:11434/api/generate

echo.
echo.

:: 列出已安装的模型
echo Listing installed models...
ollama list

echo.
echo.

:: 检查 Ollama 进程
echo Checking Ollama process...
tasklist | findstr "ollama"

echo.
echo.

:: 检查端口状态
echo Checking port 11434...
netstat -an | findstr "11434"

pause