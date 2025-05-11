#!/usr/bin/env python3
# 测试 CosyVoice2-Ex FastAPI TTS 服务

import requests
import json
import argparse
import time
import os
from datetime import datetime

# 默认参数
DEFAULT_HOST = "localhost"
DEFAULT_PORT = 9881  # 默认端口，可通过命令行参数修改
DEFAULT_SPEAKER = "zh_F_1"  # 默认音色
DEFAULT_API_KEY = "cosyvoice-api-demo"  # 默认 API 密钥

def get_available_speakers(host, port, api_key=None):
    """获取可用的音色列表"""
    url = f"http://{host}:{port}/speakers"
    headers = {}
    if api_key:
        headers["X-API-Key"] = api_key
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"获取音色列表失败: HTTP {response.status_code}")
            print(response.text)
            return []
    except Exception as e:
        print(f"请求失败: {str(e)}")
        return []

def test_tts_get(text, speaker, host, port, instruct=None, streaming=False, speed=1.0, api_key=None):
    """测试 GET 方式的 TTS 接口"""
    url = f"http://{host}:{port}/tts"
    params = {
        "text": text,
        "speaker": speaker,
        "streaming": 1 if streaming else 0,
        "speed": speed
    }
    
    if instruct:
        params["instruct"] = instruct
    
    headers = {}
    if api_key:
        headers["X-API-Key"] = api_key
    
    try:
        # 记录开始时间
        start_time = time.time()
        
        # 发送请求
        response = requests.get(url, params=params, headers=headers)
        
        # 计算响应时间
        elapsed_time = time.time() - start_time
        
        if response.status_code == 200:
            # 获取当前时间作为文件名的一部分
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # 根据 streaming 参数设置文件扩展名
            extension = "ogg" if streaming else "wav"
            
            # 创建保存文件的文件名
            filename = f"output/tts_test_{timestamp}.{extension}"
            
            # 确保输出目录存在
            os.makedirs("output", exist_ok=True)
            
            # 保存音频文件
            with open(filename, "wb") as f:
                f.write(response.content)
            
            print(f"GET 请求成功! 响应时间: {elapsed_time:.2f}秒")
            print(f"音频文件已保存到: {filename}")
            return True
        else:
            print(f"GET 请求失败: HTTP {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"GET 请求异常: {str(e)}")
        return False

def test_tts_post(text, speaker, host, port, instruct=None, streaming=False, speed=1.0, api_key=None):
    """测试 POST 方式的 TTS 接口"""
    url = f"http://{host}:{port}/tts"
    
    # 构建请求体
    data = {
        "text": text,
        "speaker": speaker,
        "streaming": streaming,
        "speed": speed
    }
    
    if instruct:
        data["instruct"] = instruct
    
    headers = {
        "Content-Type": "application/json"
    }
    
    if api_key:
        headers["X-API-Key"] = api_key
    
    try:
        # 记录开始时间
        start_time = time.time()
        
        # 发送请求
        response = requests.post(url, json=data, headers=headers)
        
        # 计算响应时间
        elapsed_time = time.time() - start_time
        
        if response.status_code == 200:
            # 获取当前时间作为文件名的一部分
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # 根据 streaming 参数设置文件扩展名
            extension = "ogg" if streaming else "wav"
            
            # 创建保存文件的文件名
            filename = f"output/tts_test_post_{timestamp}.{extension}"
            
            # 确保输出目录存在
            os.makedirs("output", exist_ok=True)
            
            # 保存音频文件
            with open(filename, "wb") as f:
                f.write(response.content)
            
            print(f"POST 请求成功! 响应时间: {elapsed_time:.2f}秒")
            print(f"音频文件已保存到: {filename}")
            return True
        else:
            print(f"POST 请求失败: HTTP {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"POST 请求异常: {str(e)}")
        return False

def test_health_check(host, port):
    """测试健康检查接口"""
    url = f"http://{host}:{port}/health"
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            result = response.json()
            print("健康检查成功:")
            print(f"  状态: {result.get('status')}")
            print(f"  服务: {result.get('service')}")
            return True
        else:
            print(f"健康检查失败: HTTP {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"健康检查请求异常: {str(e)}")
        return False

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="测试 CosyVoice2-Ex FastAPI TTS 服务")
    parser.add_argument("--host", default=DEFAULT_HOST, help=f"API 主机地址 (默认: {DEFAULT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help=f"API 端口 (默认: {DEFAULT_PORT})")
    parser.add_argument("--text", default="你好，世界。这是一个测试。", help="要转换为语音的文本")
    parser.add_argument("--speaker", default=DEFAULT_SPEAKER, help=f"音色ID (默认: {DEFAULT_SPEAKER})")
    parser.add_argument("--instruct", help="指令，用于控制语音风格，例如: '用开心的语气说'")
    parser.add_argument("--streaming", action="store_true", help="是否使用流式输出")
    parser.add_argument("--speed", type=float, default=1.0, help="语速，范围0.5-2.0 (默认: 1.0)")
    parser.add_argument("--api-key", default=DEFAULT_API_KEY, help=f"API密钥 (默认: {DEFAULT_API_KEY})")
    parser.add_argument("--list-speakers", action="store_true", help="列出所有可用的音色")
    parser.add_argument("--method", choices=["get", "post", "both"], default="both", help="使用的HTTP方法 (默认: both)")
    parser.add_argument("--health", action="store_true", help="检查服务健康状态")
    
    args = parser.parse_args()
    
    # 健康检查
    if args.health:
        test_health_check(args.host, args.port)
        return
    
    # 获取可用音色列表
    if args.list_speakers:
        speakers = get_available_speakers(args.host, args.port, args.api_key)
        if speakers:
            print("\n可用音色列表:")
            for i, speaker in enumerate(speakers):
                print(f"{i+1}. ID: {speaker.get('voice_id')}, 名称: {speaker.get('name')}")
        return
    
    # 测试 TTS
    if args.method in ["get", "both"]:
        test_tts_get(args.text, args.speaker, args.host, args.port, 
                    args.instruct, args.streaming, args.speed, args.api_key)
    
    if args.method in ["post", "both"]:
        test_tts_post(args.text, args.speaker, args.host, args.port,
                     args.instruct, args.streaming, args.speed, args.api_key)

if __name__ == "__main__":
    main() 