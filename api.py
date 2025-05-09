import time
import io, os, sys
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append('{}/third_party/AcademiCodec'.format(ROOT_DIR))
sys.path.append('{}/third_party/Matcha-TTS'.format(ROOT_DIR))
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))

import requests
from pydub import AudioSegment

import numpy as np
from flask import Flask, request, Response, send_from_directory, make_response
import torch
import torchaudio

from cosyvoice.cli.cosyvoice import CosyVoice, CosyVoice2
from cosyvoice.utils.file_utils import load_wav
import torchaudio
import ffmpeg

from flask_cors import CORS
import shutil
import json
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('cosyvoice_api')

# 创建应用函数，允许在测试时传入不同配置
def create_app(config=None):
    app = Flask(__name__)
    
    # 应用配置
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 限制请求体大小为16MB
    
    # 如果提供了配置，则应用它
    if config:
        app.config.update(config)
    
    # 设置CORS
    CORS(app, resources={r"/*": {"origins": "*"}})
    
    # 初始化模型
    # 将初始化移至需要时惰性加载，避免导入时就加载模型
    app.cosyvoice = None
    app.default_voices = []
    app.spk_custom = []
    
    # 初始化函数
    def initialize_model():
        if app.cosyvoice is None:
            logger.info("初始化CosyVoice2模型...")
            app.cosyvoice = CosyVoice2('pretrained_models/CosyVoice2-0.5B')
            app.default_voices = app.cosyvoice.list_available_spks()
            
            app.spk_custom = []
            voices_dir = f"{ROOT_DIR}/voices/"
            if os.path.exists(voices_dir):
                for name in os.listdir(voices_dir):
                    if name.endswith('.pt'):
                        app.spk_custom.append(name.replace(".pt", ""))
            
            logger.info(f"默认音色: {app.default_voices}")
            logger.info(f"自定义音色: {app.spk_custom}")
    
    # 注册初始化函数
    app.initialize_model = initialize_model
    
    def process_audio(tts_speeches, sample_rate=22050, format="wav"):
        """处理音频数据并返回响应"""
        buffer = io.BytesIO()
        audio_data = torch.concat(tts_speeches, dim=1)
        torchaudio.save(buffer, audio_data, sample_rate, format=format)
        buffer.seek(0)
        return buffer

    def create_audio_response(buffer, format="wav"):
        """创建音频响应"""
        if format == "wav":
            return Response(buffer.read(), mimetype="audio/wav")
        else:
            response = make_response(buffer.read())
            response.headers['Content-Type'] = f'audio/{format}'
            response.headers['Content-Disposition'] = f'attachment; filename=sound.{format}'
            return response

    def load_voice_data(speaker):
        """加载语音数据"""
        voice_path = f"{ROOT_DIR}/voices/{speaker}.pt"
        try:
            device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
            if not os.path.exists(voice_path):
                return None
            voice_data = torch.load(voice_path, map_location=device)
            return voice_data.get('audio_ref')
        except Exception as e:
            logger.error(f"加载音色文件失败: {e}")
            raise ValueError(f"加载音色文件失败: {e}")

    @app.route("/", methods=['GET', 'POST'])
    @app.route("/tts", methods=['GET', 'POST'])
    def tts():
        # 确保模型已初始化
        app.initialize_model()
        
        try:
            # 获取参数
            params = request.get_json() if request.method == 'POST' else request.args
            text = params.get('text')
            speaker = params.get('speaker')
            instruct = params.get('instruct')
            streaming = int(params.get('streaming', 0))
            speed = float(params.get('speed', 1.0))

            # 验证必要参数
            if not text or not speaker:
                return {"error": "文本和角色名不能为空"}, 400

            # 处理 instruct 模式
            if instruct:
                prompt_speech_16k = load_voice_data(speaker)
                if prompt_speech_16k is None:
                    return {"error": "预训练音色文件中缺少audio_ref数据！"}, 500
                
                inference_func = lambda: app.cosyvoice.inference_instruct2(
                    text, instruct, prompt_speech_16k, stream=bool(streaming), speed=speed
                )
            else:
                inference_func = lambda: app.cosyvoice.inference_sft(
                    text, speaker, stream=bool(streaming), speed=speed
                )

            # 处理流式输出
            if streaming:
                def generate():
                    for _, i in enumerate(inference_func()):
                        buffer = process_audio([i['tts_speech']], format="ogg")
                        yield buffer.read()
                
                response = make_response(generate())
                response.headers.update({
                    'Content-Type': 'audio/ogg',
                    'Content-Disposition': 'attachment; filename=sound.ogg'
                })
                return response
            
            # 处理非流式输出
            tts_speeches = [i['tts_speech'] for _, i in enumerate(inference_func())]
            buffer = process_audio(tts_speeches, format="wav")
            return create_audio_response(buffer)
        except Exception as e:
            logger.error(f"TTS生成过程中发生错误: {str(e)}")
            return {"error": f"服务器内部错误: {str(e)}"}, 500

    @app.route("/speakers", methods=['GET', 'POST'])
    def speakers():
        # 确保模型已初始化
        app.initialize_model()
        
        try:
            voices = []

            for x in app.default_voices:
                voices.append({"name":x,"voice_id":x})

            for name in app.spk_custom:
                voices.append({"name":name,"voice_id":name})

            response = app.response_class(
                response=json.dumps(voices),
                status=200,
                mimetype='application/json'
            )
            return response
        except Exception as e:
            logger.error(f"获取音色列表时发生错误: {str(e)}")
            return {"error": f"服务器内部错误: {str(e)}"}, 500
            
    # 健康检查端点
    @app.route("/health", methods=['GET'])
    def health_check():
        return {"status": "healthy", "service": "CosyVoice2 API"}, 200
    
    return app

# 创建应用实例 - 仅在直接运行此文件时使用开发服务器
app = create_app()

if __name__ == "__main__":
    # 开发服务器配置
    app.initialize_model()  # 提前初始化模型
    app.run(host='0.0.0.0', port=9880, debug=False)
    logger.warning("使用开发服务器运行。不要在生产环境中使用此配置，请使用WSGI服务器。")
