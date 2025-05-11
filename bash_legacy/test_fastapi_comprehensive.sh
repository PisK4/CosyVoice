#!/bin/bash
# CosyVoice2-Ex FastAPI 综合测试脚本
# 测试 FastAPI 服务的所有接口和功能

# 设置变量
HOST="localhost"
PORT="9881"
API_URL="http://${HOST}:${PORT}"
API_KEY="cosyvoice-api-demo"
OUTPUT_DIR="test_output"

# 颜色配置
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 创建输出目录
mkdir -p $OUTPUT_DIR

# 显示测试信息
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}CosyVoice2-Ex FastAPI 综合测试${NC}"
echo -e "${BLUE}=======================================${NC}"
echo "API 地址: ${API_URL}"
echo "API 密钥: ${API_KEY}"
echo "输出目录: ${OUTPUT_DIR}"
echo

# 测试1: 健康检查
echo -e "${YELLOW}[1/5] 测试健康检查接口...${NC}"
HEALTH_RESPONSE=$(curl -s "${API_URL}/health")
if [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
    echo -e "${GREEN}✓ 健康检查成功${NC}"
    echo "响应: ${HEALTH_RESPONSE}"
else
    echo -e "${RED}✗ 健康检查失败${NC}"
    echo "响应: ${HEALTH_RESPONSE}"
    echo "无法继续测试，API 服务可能未启动"
    exit 1
fi
echo

# 测试2: 音色列表
echo -e "${YELLOW}[2/5] 测试获取音色列表...${NC}"
SPEAKERS_RESPONSE=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/speakers")
if [[ $SPEAKERS_RESPONSE == *"voice_id"* ]]; then
    VOICE_COUNT=$(echo $SPEAKERS_RESPONSE | grep -o "voice_id" | wc -l)
    echo -e "${GREEN}✓ 获取音色列表成功，共 ${VOICE_COUNT} 个音色${NC}"
    
    # 提取第一个音色ID
    FIRST_VOICE=$(echo $SPEAKERS_RESPONSE | sed -n 's/.*"voice_id":"\([^"]*\)".*/\1/p' | head -n 1)
    echo "将使用音色: ${FIRST_VOICE}"
    
    # 保存音色列表到文件
    echo $SPEAKERS_RESPONSE | python -m json.tool > "${OUTPUT_DIR}/speakers.json"
    echo "音色列表已保存到: ${OUTPUT_DIR}/speakers.json"
else
    echo -e "${RED}✗ 获取音色列表失败${NC}"
    echo "响应: ${SPEAKERS_RESPONSE}"
    echo "无法继续测试，需要获取有效的音色ID"
    exit 1
fi
echo

# 测试3: GET 方式文本转语音
echo -e "${YELLOW}[3/5] 测试 GET 方式文本转语音...${NC}"
TEXT="这是FastAPI测试，使用音色${FIRST_VOICE}"
ENCODED_TEXT=$(echo "$TEXT" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
OUTPUT_FILE="${OUTPUT_DIR}/tts_get_${FIRST_VOICE}.wav"

echo "文本: ${TEXT}"
echo "发送GET请求..."
TTS_GET_RESPONSE=$(curl -s -w "%{http_code}" -H "X-API-Key: ${API_KEY}" -o "${OUTPUT_FILE}" "${API_URL}/tts?text=${ENCODED_TEXT}&speaker=${FIRST_VOICE}")

if [ "$TTS_GET_RESPONSE" == "200" ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "${GREEN}✓ GET方式文本转语音成功${NC}"
    echo "音频文件: ${OUTPUT_FILE} (${FILE_SIZE})"
    
    # 检测操作系统并提供播放命令
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "可使用命令播放: afplay ${OUTPUT_FILE}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "可使用命令播放: aplay ${OUTPUT_FILE}"
    fi
else
    echo -e "${RED}✗ GET方式文本转语音失败${NC}"
    echo "HTTP状态码: ${TTS_GET_RESPONSE}"
    if [ -f "$OUTPUT_FILE" ]; then
        CONTENT=$(cat "${OUTPUT_FILE}")
        echo "错误详情: ${CONTENT}"
    fi
fi
echo

# 测试4: POST 方式文本转语音
echo -e "${YELLOW}[4/5] 测试 POST 方式文本转语音...${NC}"
TEXT="这是FastAPI POST请求测试，使用音色${FIRST_VOICE}"
OUTPUT_FILE="${OUTPUT_DIR}/tts_post_${FIRST_VOICE}.wav"

echo "文本: ${TEXT}"
echo "发送POST请求..."
TTS_POST_RESPONSE=$(curl -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ${API_KEY}" \
    -o "${OUTPUT_FILE}" \
    -d "{\"text\":\"${TEXT}\",\"speaker\":\"${FIRST_VOICE}\",\"speed\":1.2}" \
    "${API_URL}/tts")

if [ "$TTS_POST_RESPONSE" == "200" ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "${GREEN}✓ POST方式文本转语音成功${NC}"
    echo "音频文件: ${OUTPUT_FILE} (${FILE_SIZE})"
    
    # 检测操作系统并提供播放命令
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "可使用命令播放: afplay ${OUTPUT_FILE}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "可使用命令播放: aplay ${OUTPUT_FILE}"
    fi
else
    echo -e "${RED}✗ POST方式文本转语音失败${NC}"
    echo "HTTP状态码: ${TTS_POST_RESPONSE}"
    if [ -f "$OUTPUT_FILE" ]; then
        CONTENT=$(cat "${OUTPUT_FILE}")
        echo "错误详情: ${CONTENT}"
    fi
fi
echo

# 测试5: API 认证测试
echo -e "${YELLOW}[5/5] 测试 API 认证...${NC}"
AUTH_TEST_FILE="${OUTPUT_DIR}/auth_test.txt"
AUTH_RESPONSE=$(curl -s -o "${AUTH_TEST_FILE}" -w "%{http_code}" "${API_URL}/tts?text=测试认证&speaker=${FIRST_VOICE}")

# 检查响应状态码，401意味着需要认证，这是预期结果
if [ "$AUTH_RESPONSE" == "401" ]; then
    echo -e "${GREEN}✓ API 认证检查正常工作${NC}"
    if [ -f "${AUTH_TEST_FILE}" ]; then
        CONTENT=$(cat "${AUTH_TEST_FILE}")
        echo "响应内容: ${CONTENT}"
    fi
elif [ "$AUTH_RESPONSE" == "400" ] && [ -f "${AUTH_TEST_FILE}" ] && grep -q "API" "${AUTH_TEST_FILE}"; then
    echo -e "${GREEN}✓ API 认证检查正常工作 (使用400状态码)${NC}"
    if [ -f "${AUTH_TEST_FILE}" ]; then
        CONTENT=$(cat "${AUTH_TEST_FILE}")
        echo "响应内容: ${CONTENT}"
    fi
else
    echo -e "${RED}✗ API 认证检查失败${NC}"
    echo "HTTP状态码: ${AUTH_RESPONSE}"
    if [ -f "${AUTH_TEST_FILE}" ]; then
        CONTENT=$(cat "${AUTH_TEST_FILE}")
        echo "响应内容: ${CONTENT}"
    fi
fi
echo

# 测试总结
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}测试完成!${NC}"
echo -e "${BLUE}=======================================${NC}"
echo "测试结果:"
echo "  - 健康检查: $([ "$HEALTH_RESPONSE" == *"healthy"* ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "  - 音色列表: $([ "$SPEAKERS_RESPONSE" == *"voice_id"* ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "  - GET方式TTS: $([ "$TTS_GET_RESPONSE" == "200" ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "  - POST方式TTS: $([ "$TTS_POST_RESPONSE" == "200" ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "  - API认证: $([ "$AUTH_RESPONSE" == "401" ] || ([ "$AUTH_RESPONSE" == "400" ] && grep -q "API" "${AUTH_TEST_FILE}") && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo
echo "测试输出保存在 ${OUTPUT_DIR} 目录"
echo "API服务文档: ${API_URL}/docs" 