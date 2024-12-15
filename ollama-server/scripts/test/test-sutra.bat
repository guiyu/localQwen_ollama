@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 设置根目录
set "OLLAMA_ROOT=D:\workspaces\localQwen_ollama\ollama-server"
cd /d "%OLLAMA_ROOT%"

:: 检查环境
call "%OLLAMA_ROOT%\scripts\utils\check_env.bat"
if %errorlevel% neq 0 (
    echo Environment check failed. Please run setup_env.bat first.
    exit /b 1
)

:: 创建结果目录
set "RESULTS_DIR=%OLLAMA_ROOT%\logs\test_results"
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

:: 设置时间戳
set "timestamp=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=%timestamp: =0%"
set "result_file=%RESULTS_DIR%\test_results_%timestamp%.txt"

echo =================================
echo Testing Ollama API Basic Function
echo =================================

:: 1. 基础功能测试
echo.
echo 1. Testing basic chat functionality...
echo.
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请用一句话解释金刚经的核心思想。\"}" ^
  http://localhost:11434/api/generate > "%result_file%"

:: 2. 不同温度参数测试
echo.
echo 2. Testing with different parameters...
echo.
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"以诗歌形式阐述金刚经的智慧\",\"temperature\":0.9}" ^
  http://localhost:11434/api/generate >> "%result_file%"

:: 3. 长文本测试
echo.
echo 3. Testing long text processing...
echo.
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请详细解释金刚经中'无我相、无人相、无众生相、无寿者相'的含义。\",\"num_ctx\":2048}" ^
  http://localhost:11434/api/generate >> "%result_file%"

:: 4. 性能测试
echo.
echo 4. Performance testing...
set "start_time=%time%"
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"金刚经讲了什么？\"}" ^
  http://localhost:11434/api/generate >> "%result_file%"
set "end_time=%time%"
echo Start Time: %start_time% >> "%result_file%"
echo End Time: %end_time% >> "%result_file%"

:: 运行分析
echo.
echo Running analysis...
python "%OLLAMA_ROOT%\src\analysis\response_analyzer.py" "%result_file%"

echo.
echo Test completed. Results saved to: %result_file%
echo.
type "%result_file%"

pause@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 设置根目录
set "OLLAMA_ROOT=D:\workspaces\localQwen_ollama\ollama-server"
cd /d "%OLLAMA_ROOT%"

:: 检查环境
call "%OLLAMA_ROOT%\scripts\utils\check_env.bat"
if %errorlevel% neq 0 (
    echo Environment check failed. Please run setup_env.bat first.
    exit /b 1
)

:: 创建结果目录
set "RESULTS_DIR=%OLLAMA_ROOT%\logs\test_results"
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

:: 设置时间戳
set "timestamp=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=%timestamp: =0%"
set "result_file=%RESULTS_DIR%\test_results_%timestamp%.txt"

echo =================================
echo Testing Ollama API Basic Function
echo =================================

:: 1. 基础功能测试
echo.
echo 1. Testing basic chat functionality...
echo.
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请用一句话解释金刚经的核心思想。\"}" ^
  http://localhost:11434/api/generate > "%result_file%"

:: 2. 不同温度参数测试
echo.
echo 2. Testing with different parameters...
echo.
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"以诗歌形式阐述金刚经的智慧\",\"temperature\":0.9}" ^
  http://localhost:11434/api/generate >> "%result_file%"

:: 3. 长文本测试
echo.
echo 3. Testing long text processing...
echo.
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请详细解释金刚经中'无我相、无人相、无众生相、无寿者相'的含义。\",\"num_ctx\":2048}" ^
  http://localhost:11434/api/generate >> "%result_file%"

:: 4. 性能测试
echo.
echo 4. Performance testing...
set "start_time=%time%"
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"金刚经讲了什么？\"}" ^
  http://localhost:11434/api/generate >> "%result_file%"
set "end_time=%time%"
echo Start Time: %start_time% >> "%result_file%"
echo End Time: %end_time% >> "%result_file%"

:: 运行分析
echo.
echo Running analysis...
python "%OLLAMA_ROOT%\src\analysis\response_analyzer.py" "%result_file%"

echo.
echo Test completed. Results saved to: %result_file%
echo.
type "%result_file%"

pause