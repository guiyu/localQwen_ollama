#!/bin/bash

# 测试配置
API_HOST="localhost"
API_PORT="8080"
MODEL="qwen:7b-chat"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 测试API健康状态
echo -e "${GREEN}Testing API health...${NC}"
curl -s "http://$API_HOST:$API_PORT/api/health"
echo

# 测试基本对话
echo -e "\n${GREEN}Testing basic chat...${NC}"
curl -X POST "http://$API_HOST:$API_PORT/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"Hello, how are you?\"}"
echo

# 测试响应时间
echo -e "\n${GREEN}Testing response time...${NC}"
time curl -s -X POST "http://$API_HOST:$API_PORT/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"What is 1+1?\"}" > /dev/null

# 测试并发请求
echo -e "\n${GREEN}Testing concurrent requests...${NC}"
for i in {1..5}; do
    curl -s -X POST "http://$API_HOST:$API_PORT/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$MODEL\",\"prompt\":\"Quick test $i\"}" &
done
wait

echo -e "\n${GREEN}Tests completed!${NC}"