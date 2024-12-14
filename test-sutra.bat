@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 激活 Conda 环境
call conda activate ollama_test

:: 检查环境
python check_env.py
if %errorlevel% neq 0 (
    echo Environment check failed. Please run setup_env.bat first.
    pause
    exit /b
)

:: 创建结果目录
if not exist "results" mkdir results
set "timestamp=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=%timestamp: =0%"
set "result_file=results\test_results_%timestamp%.txt"

echo Ollama API Test Report - %date% %time% > %result_file%
echo ================================================== >> %result_file%

:: 1. 基础网络连接测试
echo Testing API Connection...
echo [1. API Connection Test] >> %result_file%
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"你在吗？\"}" ^
  http://localhost:11434/api/generate >> %result_file% 2>&1

:: 2. 不同温度参数测试
echo.
echo Testing Different Temperature Settings... 
echo. >> %result_file%
echo [2. Temperature Parameter Tests] >> %result_file%

:: 低温度测试 (更确定性的回答)
echo Testing Low Temperature (0.1)... >> %result_file%
set "start_time=%time%"
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请用100字解释金刚经中'无我相、无人相、无众生相、无寿者相'的含义\",\"temperature\":0.1}" ^
  http://localhost:11434/api/generate >> %result_file%
echo Response Time (Low Temp): %start_time% - %time% >> %result_file%

:: 高温度测试 (更有创造性的回答)
echo. >> %result_file%
echo Testing High Temperature (0.9)... >> %result_file%
set "start_time=%time%"
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请用诗歌的形式阐释金刚经的核心思想\",\"temperature\":0.9}" ^
  http://localhost:11434/api/generate >> %result_file%
echo Response Time (High Temp): %start_time% - %time% >> %result_file%

:: 3. 响应时间测试
echo. >> %result_file%
echo [3. Response Time Test] >> %result_file%
for /l %%i in (1,1,5) do (
    echo Test %%i of 5... >> %result_file%
    set "start_time=!time!"
    curl -s -X POST ^
      -H "Content-Type: application/json" ^
      -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"金刚经的作者是谁？\"}" ^
      http://localhost:11434/api/generate >> %result_file%
    echo Response Time: !start_time! - !time! >> %result_file%
    echo. >> %result_file%
)

:: 4. 上下文长度测试
echo. >> %result_file%
echo [4. Context Length Test] >> %result_file%
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请详细解释金刚经全文的结构和主要章节内容\",\"num_ctx\":2048}" ^
  http://localhost:11434/api/generate >> %result_file%

:: 5. 错误处理测试
echo. >> %result_file%
echo [5. Error Handling Test] >> %result_file%
:: 测试无效模型
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"invalid_model\",\"prompt\":\"test\"}" ^
  http://localhost:11434/api/generate >> %result_file% 2>&1

:: 测试超长输入
set "long_prompt="
for /l %%i in (1,1,1000) do set "long_prompt=!long_prompt!金"
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"!long_prompt!\"}" ^
  http://localhost:11434/api/generate >> %result_file% 2>&1

:: 6. 性能基准测试
echo. >> %result_file%
echo [6. Performance Benchmark] >> %result_file%
echo Testing response times for different prompt lengths... >> %result_file%

:: 短文本测试
set "start_time=%time%"
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"金刚经讲了什么？\"}" ^
  http://localhost:11434/api/generate >> %result_file%
echo Short prompt response time: %start_time% - %time% >> %result_file%

:: 中等文本测试
set "start_time=%time%"
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请解释金刚经中'应无所住而生其心'的含义，并举例说明其在现代生活中的应用。\"}" ^
  http://localhost:11434/api/generate >> %result_file%
echo Medium prompt response time: %start_time% - %time% >> %result_file%

:: 长文本测试
set "start_time=%time%"
curl -s -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"qwen:7b-chat\",\"prompt\":\"请详细分析金刚经中'一切有为法，如梦幻泡影，如露亦如电，应作如是观'这句偈语的深层含义，并结合现代科学和哲学思想进行阐释。\"}" ^
  http://localhost:11434/api/generate >> %result_file%
echo Long prompt response time: %start_time% - %time% >> %result_file%

:: 生成测试报告摘要
echo. >> %result_file%
echo ==================== >> %result_file%
echo Test Summary >> %result_file%
echo ==================== >> %result_file%
echo Test completed at: %date% %time% >> %result_file%
echo Results saved in: %result_file%

echo.
echo Test completed. Results saved to: %result_file%
echo.

:: 创建分析脚本（Python）
echo import json > analyze_results.py
echo import pandas as pd >> analyze_results.py
echo import matplotlib.pyplot as plt >> analyze_results.py
echo. >> analyze_results.py
echo # Add analysis code here >> analyze_results.py

:: 如果安装了Python，则运行分析
where python >nul 2>nul
if %errorlevel%==0 (
    python analyze_results.py
)

pause