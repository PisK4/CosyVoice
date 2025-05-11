#!/bin/bash
# 测试 CosyVoice2-Ex FastAPI 服务的基本功能

# 默认参数
HOST="localhost"
PORT="9881"
API_KEY="cosyvoice-api-demo"

# 命令行参数解析
while [[ $# -gt 0 ]]; do
  case $1 in
    --host)
      HOST="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --api-key)
      API_KEY="$2"
      shift 2
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

# 颜色配置
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# API 基础 URL
BASE_URL="http://${HOST}:${PORT}"

# 显示测试信息
echo -e "${YELLOW}测试 CosyVoice2-Ex FastAPI 服务${NC}"
echo "API 地址: ${BASE_URL}"
echo "API 密钥: ${API_KEY}"
echo "-----------------------------------"

# 创建输出目录
mkdir -p output

# 测试健康检查
echo -e "${YELLOW}1. 测试健康检查接口...${NC}"
HEALTH_RESPONSE=$(curl -s "${BASE_URL}/health")
if [ $? -eq 0 ] && [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
  echo -e "${GREEN}健康检查成功${NC}"
  echo "响应: ${HEALTH_RESPONSE}"
else
  echo -e "${RED}健康检查失败${NC}"
  echo "响应: ${HEALTH_RESPONSE}"
  echo "无法继续测试，API 服务可能未启动"
  exit 1
fi
echo "-----------------------------------"

# 测试获取可用音色列表
echo -e "${YELLOW}2. 测试获取可用音色列表...${NC}"
SPEAKERS_RESPONSE=$(curl -s -H "X-API-Key: ${API_KEY}" "${BASE_URL}/speakers")
if [ $? -eq 0 ] && [[ $SPEAKERS_RESPONSE == *"voice_id"* ]]; then
  echo -e "${GREEN}获取音色列表成功${NC}"
  VOICE_COUNT=$(echo $SPEAKERS_RESPONSE | grep -o "voice_id" | wc -l)
  echo "音色数量: ${VOICE_COUNT}"
  
  # 提取第一个音色 ID
  FIRST_VOICE=$(echo $SPEAKERS_RESPONSE | sed -n 's/.*"voice_id":"\([^"]*\)".*/\1/p' | head -n 1)
  
  if [ -z "$FIRST_VOICE" ]; then
    echo -e "${RED}无法提取音色ID${NC}"
    echo "获取的响应: ${SPEAKERS_RESPONSE}"
    exit 1
  else
    echo -e "${BLUE}将使用音色: ${FIRST_VOICE}${NC}"
  fi
else
  echo -e "${RED}获取音色列表失败${NC}"
  echo "响应: ${SPEAKERS_RESPONSE}"
  echo "无法继续测试，需要获取有效的音色ID"
  exit 1
fi
echo "-----------------------------------"

# 测试 TTS 服务 (GET)
echo -e "${YELLOW}3. 测试 TTS 服务 (GET)...${NC}"
OUTPUT_FILE="output/test_tts_get.wav"
TTS_GET_RESPONSE=$(curl -s -o "${OUTPUT_FILE}" -w "%{http_code}" -H "X-API-Key: ${API_KEY}" "${BASE_URL}/tts?text=你好世界&speaker=${FIRST_VOICE}")
if [ "$TTS_GET_RESPONSE" == "200" ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo -e "${GREEN}TTS GET 请求成功${NC}"
  echo "音频文件已保存到: ${OUTPUT_FILE}"
  echo "文件大小: $(du -h "${OUTPUT_FILE}" | cut -f1)"
else
  echo -e "${RED}TTS GET 请求失败${NC}"
  echo "HTTP 状态码: ${TTS_GET_RESPONSE}"
  if [ -f "$OUTPUT_FILE" ]; then
    CONTENT=$(cat "${OUTPUT_FILE}")
    if [[ $CONTENT == *"detail"* ]]; then
      echo "错误详情: ${CONTENT}"
    fi
  fi
fi
echo "-----------------------------------"

# 测试 TTS 服务 (POST)
echo -e "${YELLOW}4. 测试 TTS 服务 (POST)...${NC}"
OUTPUT_FILE="output/test_tts_post.wav"
TTS_POST_RESPONSE=$(curl -s -o "${OUTPUT_FILE}" -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d "{\"text\":\"这是一个POST请求测试\",\"speaker\":\"${FIRST_VOICE}\"}" \
  "${BASE_URL}/tts")
if [ "$TTS_POST_RESPONSE" == "200" ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo -e "${GREEN}TTS POST 请求成功${NC}"
  echo "音频文件已保存到: ${OUTPUT_FILE}"
  echo "文件大小: $(du -h "${OUTPUT_FILE}" | cut -f1)"
else
  echo -e "${RED}TTS POST 请求失败${NC}"
  echo "HTTP 状态码: ${TTS_POST_RESPONSE}"
  if [ -f "$OUTPUT_FILE" ]; then
    CONTENT=$(cat "${OUTPUT_FILE}")
    if [[ $CONTENT == *"detail"* ]]; then
      echo "错误详情: ${CONTENT}"
    fi
  fi
fi
echo "-----------------------------------"

# 测试认证失败
echo -e "${YELLOW}5. 测试 API 认证失败...${NC}"
AUTH_TEST_FILE="output/auth_test.txt"
AUTH_RESPONSE=$(curl -s -o "${AUTH_TEST_FILE}" -w "%{http_code}" "${BASE_URL}/tts?text=测试&speaker=${FIRST_VOICE}")

# 检查响应状态码，401意味着需要认证，这是我们希望的结果
if [[ "$AUTH_RESPONSE" == "401" ]]; then
  echo -e "${GREEN}API 认证检查正常工作${NC}"
  if [ -f "${AUTH_TEST_FILE}" ]; then
    CONTENT=$(cat "${AUTH_TEST_FILE}")
    echo "响应内容: ${CONTENT}"
  fi
# 有时候会返回400而不是401，这也是可接受的
elif [[ "$AUTH_RESPONSE" == "400" && -f "${AUTH_TEST_FILE}" && $(cat "${AUTH_TEST_FILE}" | grep -c "API") -gt 0 ]]; then
  echo -e "${GREEN}API 认证检查正常工作 (使用400状态码)${NC}"
  if [ -f "${AUTH_TEST_FILE}" ]; then
    CONTENT=$(cat "${AUTH_TEST_FILE}")
    echo "响应内容: ${CONTENT}"
  fi
else
  echo -e "${RED}API 认证检查失败${NC}"
  echo "HTTP 状态码: ${AUTH_RESPONSE}"
  if [ -f "${AUTH_TEST_FILE}" ]; then
    CONTENT=$(cat "${AUTH_TEST_FILE}")
    echo "响应内容: ${CONTENT}"
  fi
fi
echo "-----------------------------------"

echo -e "${YELLOW}测试完成!${NC}" 