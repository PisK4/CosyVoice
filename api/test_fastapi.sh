#!/bin/bash
# CosyVoice2-Ex FastAPI 测试脚本

# 设置测试参数
API_URL="http://localhost:9881"
API_KEY="cosyvoice-api-demo"

# 设置彩色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示标题
echo -e "${BLUE}===== CosyVoice2-Ex FastAPI 测试工具 =====${NC}"
echo -e "${BLUE}API URL: ${API_URL}${NC}"

# 检查是否启用认证
if [ "$1" == "--no-auth" ]; then
  USE_AUTH=false
  echo -e "${YELLOW}API认证已禁用${NC}"
else
  USE_AUTH=true
  echo -e "${YELLOW}使用API密钥: ${API_KEY}${NC}"
fi

# 创建临时目录
TEMP_DIR="test_output"
mkdir -p $TEMP_DIR

# 1. 测试健康检查接口
echo -e "\n${BLUE}测试健康检查接口...${NC}"
if [ "$USE_AUTH" = true ]; then
  HEALTH_RESPONSE=$(curl -s -H "X-API-Key: ${API_KEY}" ${API_URL}/health)
else
  HEALTH_RESPONSE=$(curl -s ${API_URL}/health)
fi

if [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
  echo -e "${GREEN}健康检查成功: ${HEALTH_RESPONSE}${NC}"
else
  echo -e "${RED}健康检查失败: ${HEALTH_RESPONSE}${NC}"
  echo -e "${RED}请确保FastAPI服务正在运行${NC}"
  exit 1
fi

# 2. 测试获取音色列表
echo -e "\n${BLUE}测试获取音色列表...${NC}"
if [ "$USE_AUTH" = true ]; then
  SPEAKERS_RESPONSE=$(curl -s -H "X-API-Key: ${API_KEY}" ${API_URL}/speakers)
else
  SPEAKERS_RESPONSE=$(curl -s ${API_URL}/speakers)
fi

if [[ $SPEAKERS_RESPONSE == *"voice_id"* ]]; then
  echo -e "${GREEN}获取音色列表成功${NC}"
  # 提取第一个音色ID
  SPEAKER_ID=$(echo $SPEAKERS_RESPONSE | grep -o '"voice_id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo -e "${GREEN}找到音色ID: ${SPEAKER_ID}${NC}"
else
  echo -e "${RED}获取音色列表失败: ${SPEAKERS_RESPONSE}${NC}"
  # 使用默认音色
  SPEAKER_ID="李达康"
  echo -e "${YELLOW}使用默认音色ID: ${SPEAKER_ID}${NC}"
fi

# 3. 测试GET方式的TTS接口
echo -e "\n${BLUE}测试GET方式TTS接口...${NC}"
echo -e "${YELLOW}使用音色: ${SPEAKER_ID}${NC}"
TEST_TEXT="这是一个测试语音，用于验证CosyVoice2的FastAPI接口功能。"

# 构建curl命令
if [ "$USE_AUTH" = true ]; then
  GET_CMD="curl -s -H \"X-API-Key: ${API_KEY}\" \"${API_URL}/tts?text=${TEST_TEXT}&speaker=${SPEAKER_ID}&streaming=0\" -o ${TEMP_DIR}/test_get.wav"
else
  GET_CMD="curl -s \"${API_URL}/tts?text=${TEST_TEXT}&speaker=${SPEAKER_ID}&streaming=0\" -o ${TEMP_DIR}/test_get.wav"
fi

# 执行命令并显示结果
echo -e "${YELLOW}执行命令: ${GET_CMD}${NC}"
eval $GET_CMD

if [ -f "${TEMP_DIR}/test_get.wav" ] && [ -s "${TEMP_DIR}/test_get.wav" ]; then
  echo -e "${GREEN}GET方式TTS接口测试成功${NC}"
  echo -e "${GREEN}音频文件已保存到: ${TEMP_DIR}/test_get.wav${NC}"
else
  echo -e "${RED}GET方式TTS接口测试失败${NC}"
fi

# 4. 测试POST方式的TTS接口
echo -e "\n${BLUE}测试POST方式TTS接口...${NC}"
TEST_TEXT_POST="这是使用POST请求的测试，我们正在验证CosyVoice2的FastAPI接口功能。"

# 构建POST请求数据
POST_DATA="{\"text\":\"$TEST_TEXT_POST\",\"speaker\":\"$SPEAKER_ID\",\"streaming\":false,\"speed\":1.0}"

# 构建curl命令
if [ "$USE_AUTH" = true ]; then
  POST_CMD="curl -s -X POST -H \"Content-Type: application/json\" -H \"X-API-Key: ${API_KEY}\" -d '${POST_DATA}' ${API_URL}/tts -o ${TEMP_DIR}/test_post.wav"
else
  POST_CMD="curl -s -X POST -H \"Content-Type: application/json\" -d '${POST_DATA}' ${API_URL}/tts -o ${TEMP_DIR}/test_post.wav"
fi

# 执行命令并显示结果
echo -e "${YELLOW}执行命令: ${POST_CMD}${NC}"
eval $POST_CMD

if [ -f "${TEMP_DIR}/test_post.wav" ] && [ -s "${TEMP_DIR}/test_post.wav" ]; then
  echo -e "${GREEN}POST方式TTS接口测试成功${NC}"
  echo -e "${GREEN}音频文件已保存到: ${TEMP_DIR}/test_post.wav${NC}"
else
  echo -e "${RED}POST方式TTS接口测试失败${NC}"
fi

# 显示测试完成信息
echo -e "\n${BLUE}===== 测试完成 =====${NC}"
echo -e "${BLUE}测试结果保存在: ${TEMP_DIR}/ 目录${NC}"
echo -e "${YELLOW}如果遇到问题，请参考故障排除指南: api/TROUBLESHOOTING.md${NC}" 