#!/bin/bash

# CosyVoice2 API POST方法测试脚本
# 使用POST方法测试TTS API

# 设置变量
HOST="localhost"
PORT="9880"
API_URL="http://${HOST}:${PORT}/tts"
API_KEY="cosyvoice-api-demo"
SPEAKER="步非烟"
INSTRUCT=""
OUTPUT_FILE="output/${SPEAKER}_test_$(date +%Y%m%d%H%M%S)_${INSTRUCT}.wav"
TEXT="hello~hello~[breath]听得到吗?きこえていますか?初次见面?请多关照呀!这里是${SPEAKER},是你们最甜甜甜的小草莓"
SPEED=1.0

# 创建输出目录
mkdir -p output

echo "开始测试 CosyVoice2 TTS API..."
echo "使用音色: $SPEAKER"
echo "文本内容: $TEXT"
echo "语速设置: $SPEED"
echo "指令设置: $INSTRUCT"
echo "保存文件: $OUTPUT_FILE"
echo "-------------------------------------"

# 发送POST请求并保存音频文件
echo "正在生成语音，请稍候..."
RESPONSE=$(curl -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ${API_KEY}" \
    -d "{\"text\":\"${TEXT}\",\"speaker\":\"${SPEAKER}\",\"instruct\":\"${INSTRUCT}\",\"speed\":${SPEED}}" \
    -o "$OUTPUT_FILE" \
    "$API_URL")

# 检查响应状态
if [ "$RESPONSE" -eq 200 ]; then
    echo "✅ 语音生成成功！"
    echo "文件已保存至: $(pwd)/$OUTPUT_FILE"
    
    # 检查文件大小
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "文件大小: $FILE_SIZE"
    
    # 如果系统支持，提示播放方法
    if command -v afplay &> /dev/null; then
        echo "可使用命令播放: afplay $OUTPUT_FILE (macOS)"
    elif command -v aplay &> /dev/null; then
        echo "可使用命令播放: aplay $OUTPUT_FILE (Linux)"
    else
        echo "请使用音频播放器打开文件进行播放"
    fi
else
    echo "❌ 语音生成失败，HTTP状态码: $RESPONSE"
    echo "请检查API服务是否正常运行，以及认证信息是否正确"
    # 删除可能的错误输出文件
    if [ -f "$OUTPUT_FILE" ]; then
        rm "$OUTPUT_FILE"
        echo "已删除错误输出文件"
    fi
fi

echo "-------------------------------------"
echo "测试完成" 