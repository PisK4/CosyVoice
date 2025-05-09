#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
CosyVoice2-Ex FastAPI 测试脚本
测试FastAPI服务的基本功能
"""

import os
import sys
import json
import time
import argparse
import requests
from pathlib import Path

# 设置彩色输出
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_colored(text, color):
    """彩色输出文本"""
    print(f"{color}{text}{Colors.ENDC}")

def test_health(api_url, headers=None):
    """测试健康检查接口"""
    print_colored("测试健康检查接口...", Colors.HEADER)
    try:
        response = requests.get(f"{api_url}/health", headers=headers)
        if response.status_code == 200:
            print_colored(f"健康检查成功: {response.json()}", Colors.GREEN)
            return True
        else:
            print_colored(f"健康检查失败，状态码: {response.status_code}", Colors.RED)
            print_colored(f"错误: {response.text}", Colors.RED)
            return False
    except Exception as e:
        print_colored(f"测试健康检查接口时发生错误: {e}", Colors.RED)
        return False

def test_speakers(api_url, headers=None):
    """测试获取音色列表接口"""
    print_colored("测试获取音色列表接口...", Colors.HEADER)
    try:
        response = requests.get(f"{api_url}/speakers", headers=headers)
        if response.status_code == 200:
            speakers = response.json()
            print_colored(f"获取音色列表成功，共找到 {len(speakers)} 个音色", Colors.GREEN)
            # 显示前5个音色
            if speakers and len(speakers) > 0:
                print_colored("可用音色示例:", Colors.BLUE)
                for i, speaker in enumerate(speakers[:5]):
                    print_colored(f"  {i+1}. {speaker['name']} (ID: {speaker['voice_id']})", Colors.BLUE)
                # 记住第一个音色，用于后续测试
                return speakers[0]['voice_id'] if speakers else None
            return True
        else:
            print_colored(f"获取音色列表失败，状态码: {response.status_code}", Colors.RED)
            print_colored(f"错误: {response.text}", Colors.RED)
            return None
    except Exception as e:
        print_colored(f"测试获取音色列表接口时发生错误: {e}", Colors.RED)
        return None

def test_tts_get(api_url, speaker_id, headers=None):
    """测试GET方式的TTS接口"""
    if not speaker_id:
        print_colored("无法测试TTS接口: 未找到可用的音色ID", Colors.RED)
        return False
        
    print_colored(f"测试GET方式TTS接口 (音色ID: {speaker_id})...", Colors.HEADER)
    text = "这是一个测试语音，我们正在测试CosyVoice2的FastAPI接口。"
    try:
        response = requests.get(
            f"{api_url}/tts",
            params={
                "text": text,
                "speaker": speaker_id,
                "streaming": 0,
                "speed": 1.0
            },
            headers=headers
        )
        
        if response.status_code == 200:
            # 保存音频文件
            output_dir = Path("test_output")
            output_dir.mkdir(exist_ok=True)
            output_file = output_dir / "tts_get_test.wav"
            
            with open(output_file, "wb") as f:
                f.write(response.content)
                
            print_colored(f"GET方式TTS接口测试成功，音频已保存到: {output_file}", Colors.GREEN)
            return True
        else:
            print_colored(f"GET方式TTS接口测试失败，状态码: {response.status_code}", Colors.RED)
            print_colored(f"错误: {response.text}", Colors.RED)
            return False
    except Exception as e:
        print_colored(f"测试GET方式TTS接口时发生错误: {e}", Colors.RED)
        return False

def test_tts_post(api_url, speaker_id, headers=None):
    """测试POST方式的TTS接口"""
    if not speaker_id:
        print_colored("无法测试TTS接口: 未找到可用的音色ID", Colors.RED)
        return False
        
    print_colored(f"测试POST方式TTS接口 (音色ID: {speaker_id})...", Colors.HEADER)
    text = "这是使用POST请求的测试，我们正在验证CosyVoice2的FastAPI接口功能。"
    
    try:
        # 准备JSON数据
        json_data = {
            "text": text,
            "speaker": speaker_id,
            "streaming": False,
            "speed": 1.0
        }
        
        response = requests.post(
            f"{api_url}/tts",
            json=json_data,
            headers=headers
        )
        
        if response.status_code == 200:
            # 保存音频文件
            output_dir = Path("test_output")
            output_dir.mkdir(exist_ok=True)
            output_file = output_dir / "tts_post_test.wav"
            
            with open(output_file, "wb") as f:
                f.write(response.content)
                
            print_colored(f"POST方式TTS接口测试成功，音频已保存到: {output_file}", Colors.GREEN)
            return True
        else:
            print_colored(f"POST方式TTS接口测试失败，状态码: {response.status_code}", Colors.RED)
            print_colored(f"错误: {response.text}", Colors.RED)
            return False
    except Exception as e:
        print_colored(f"测试POST方式TTS接口时发生错误: {e}", Colors.RED)
        return False

def main():
    # 解析命令行参数
    parser = argparse.ArgumentParser(description="CosyVoice2-Ex FastAPI测试脚本")
    parser.add_argument("--url", default="http://localhost:9881", help="API基础URL，默认为 http://localhost:9881")
    parser.add_argument("--key", default="cosyvoice-api-demo", help="API密钥，默认为 cosyvoice-api-demo")
    parser.add_argument("--no-auth", action="store_true", help="不使用API认证")
    args = parser.parse_args()
    
    api_url = args.url
    api_key = args.key
    
    # 准备请求头
    headers = {}
    if not args.no_auth:
        headers["X-API-Key"] = api_key
    
    print_colored("=== CosyVoice2-Ex FastAPI 测试 ===", Colors.HEADER)
    print_colored(f"API URL: {api_url}", Colors.BLUE)
    print_colored(f"使用API认证: {'否' if args.no_auth else '是'}", Colors.BLUE)
    
    # 测试健康检查
    if not test_health(api_url, headers):
        print_colored("健康检查测试失败，请检查API服务是否正在运行", Colors.RED)
        sys.exit(1)
    
    # 测试音色列表
    speaker_id = test_speakers(api_url, headers)
    if not speaker_id:
        print_colored("获取音色列表测试失败，无法继续测试TTS功能", Colors.RED)
        # 提供一个默认音色ID，以防万一
        speaker_id = "李达康"
        print_colored(f"使用默认音色ID: {speaker_id}", Colors.YELLOW)
    
    # 测试TTS GET
    if not test_tts_get(api_url, speaker_id, headers):
        print_colored("GET方式TTS接口测试失败", Colors.RED)
    
    # 测试TTS POST
    if not test_tts_post(api_url, speaker_id, headers):
        print_colored("POST方式TTS接口测试失败", Colors.RED)
    
    print_colored("=== 测试完成 ===", Colors.HEADER)

if __name__ == "__main__":
    main() 