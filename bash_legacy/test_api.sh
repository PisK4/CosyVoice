#!/bin/bash

# CosyVoice2-Ex API 测试脚本
# 使用新垣结衣音色生成日文语音

# 设置变量
API_URL="http://localhost:9880/tts"
SPEAKER="邓紫棋"
OUTPUT_FILE="output/${SPEAKER}_test_$(date +%Y%m%d%H%M%S).wav"
# TEXT="こんにちは！今日も素敵な一日になりますように。笑顔を忘れずに、ゆっくり進んでいきましょうね。私も応援しています！"
TEXT="你好，世界, Hello, World"


# URL编码日文文本
ENCODED_TEXT=$(echo "$TEXT" | iconv -f utf8 -t utf8 | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')

echo "开始测试 CosyVoice2-Ex TTS API..."
echo "使用音色: $SPEAKER"
echo "日文文本: $TEXT"
echo "保存文件: $OUTPUT_FILE"
echo "-------------------------------------"

# 发送curl请求并保存音频文件
echo "正在生成语音，请稍候..."
RESPONSE=$(curl -s -w "%{http_code}" "$API_URL?text=$ENCODED_TEXT&speaker=$SPEAKER" -o "$OUTPUT_FILE")

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
    echo "请检查API服务是否正常运行，以及是否存在'$SPEAKER'音色"
    # 删除可能的错误输出文件
    if [ -f "$OUTPUT_FILE" ]; then
        rm "$OUTPUT_FILE"
    fi
fi

echo "-------------------------------------"
echo "测试完成" 