@echo off
chcp 65001
setlocal enabledelayedexpansion

echo =================================
echo Testing Ollama API Basic Function
echo =================================

echo.
echo 1. Testing basic chat functionality...
echo.

curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"你好，请介绍一下你自己\"}" ^
  http://localhost:11434/api/generate

echo.
echo.
echo 2. Testing with different parameters...
echo.

:: 测试不同温度参数
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"讲个故事\",\"temperature\":0.9}" ^
  http://localhost:11434/api/generate

echo.
pause