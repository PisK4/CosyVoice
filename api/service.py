#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
CosyVoice2-Ex API 服务模块
包含TTS服务的核心功能实现
"""

import io
import os
import sys
import torch
import torchaudio
import logging
import types
from typing import Dict, List, Generator, Optional, Union, Any

# 设置日志
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 确保第三方库可以导入
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(ROOT_DIR, 'third_party/AcademiCodec'))
sys.path.append(os.path.join(ROOT_DIR, 'third_party/Matcha-TTS'))

# 处理依赖问题
def install_dependency(package):
    """安装缺少的依赖"""
    import subprocess
    try:
        logger.info(f"尝试安装 {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        logger.info(f"已成功安装 {package}")
        return True
    except Exception as e:
        logger.error(f"安装 {package} 失败: {e}")
        return False

# 检查并安装缺少的依赖
required_packages = [
    "modelscope", 
    "onnxruntime", 
    "hyperpyyaml", 
    "python-dateutil",
    "tn",
    "pyyaml", 
    "scipy", 
    "numpy",
    "conformer",
    "diffusers",
    "accelerate"
]

for package in required_packages:
    try:
        if package == "python-dateutil":
            # 特殊处理 dateutil
            import importlib
            importlib.import_module("dateutil")
        else:
            __import__(package)
    except ImportError:
        logger.warning(f"缺少 {package} 模块，尝试安装...")
        if not install_dependency(package):
            logger.error(f"无法安装 {package}，可能影响系统运行")
            
            # 特殊处理 dateutil 依赖
            if package == "dateutil":
                install_dependency("python-dateutil")
            
            # 如果 tn 安装失败，可能是缺少 dateutil
            if package == "tn":
                install_dependency("python-dateutil")
                install_dependency("tn")

# 添加 tn.chinese 模块的补丁
import importlib.machinery
import importlib.util
import importlib

# 检查是否存在 tn.chinese 模块
tn_chinese_missing = False
try:
    importlib.import_module('tn.chinese')
except ImportError:
    logger.warning("缺少 tn.chinese 模块，将使用本地补丁替代")
    tn_chinese_missing = True

# 如果缺少 tn.chinese，导入我们的补丁
if tn_chinese_missing:
    logger.info("加载 tn 模块补丁...")
    
    # 确保 tn 模块存在
    if 'tn' not in sys.modules:
        import types
        tn_module = types.ModuleType('tn')
        sys.modules['tn'] = tn_module
    
    # 加载补丁模块
    from . import tn_patch
    
    # 创建 tn.chinese 模块
    chinese_module = types.ModuleType('tn.chinese')
    sys.modules['tn.chinese'] = chinese_module
    
    # 设置 tn.chinese.normalizer 模块
    normalizer_module = types.ModuleType('tn.chinese.normalizer')
    normalizer_module.Normalizer = tn_patch.ZhNormalizer
    sys.modules['tn.chinese.normalizer'] = normalizer_module
    
    # 创建 tn.english 模块
    english_module = types.ModuleType('tn.english')
    sys.modules['tn.english'] = english_module
    
    # 设置 tn.english.normalizer 模块
    en_normalizer_module = types.ModuleType('tn.english.normalizer')
    en_normalizer_module.Normalizer = tn_patch.EnNormalizer
    sys.modules['tn.english.normalizer'] = en_normalizer_module
    
    logger.info("tn 模块补丁加载完成")

# 使用更稳健的导入方式
try:
    # 在此处尝试导入 CosyVoice2 模块
    from cosyvoice.cli.cosyvoice import CosyVoice2
    from cosyvoice.utils.file_utils import load_wav
    from cosyvoice.utils.common import set_all_random_seed
except ImportError as e:
    logger.error(f"导入 cosyvoice 模块失败: {e}")
    # 尝试修复依赖问题并重新导入
    missing_module = str(e).split("'")[1] if "'" in str(e) else str(e).replace("No module named ", "").strip()
    if missing_module:
        # 特殊处理某些模块
        if missing_module == "dateutil":
            package_to_install = "python-dateutil"
        elif missing_module == "ttsfrd":
            # ttsfrd 是内部模块，跳过安装尝试
            logger.warning("检测到缺少 ttsfrd 模块，这是内部模块，CosyVoice2 将使用 WeTextProcessing 作为替代")
            package_to_install = None
        elif missing_module == "tn.chinese" or missing_module == "tn.chinese.normalizer":
            # 已经通过补丁处理了，不需要安装
            logger.info("使用补丁处理 tn.chinese 依赖")
            package_to_install = None
        else:
            package_to_install = missing_module
            
        if package_to_install and install_dependency(package_to_install):
            try:
                from cosyvoice.cli.cosyvoice import CosyVoice2
                from cosyvoice.utils.file_utils import load_wav
                from cosyvoice.utils.common import set_all_random_seed
                logger.info(f"成功导入 cosyvoice 模块")
            except Exception as e2:
                logger.error(f"安装依赖后导入模块失败: {e2}")
                
                # 尝试再次解决 dateutil 问题
                if 'dateutil' in str(e2):
                    install_dependency("python-dateutil")
                    try:
                        from cosyvoice.cli.cosyvoice import CosyVoice2
                        from cosyvoice.utils.file_utils import load_wav
                        from cosyvoice.utils.common import set_all_random_seed
                        logger.info(f"第二次尝试成功导入 cosyvoice 模块")
                    except Exception as e3:
                        logger.error(f"第二次尝试导入模块失败: {e3}")
                        raise RuntimeError(f"无法导入必要的模块，请尝试手动安装 {missing_module}") from e3
                else:
                    raise RuntimeError(f"无法导入必要的模块，请尝试手动安装 {missing_module}") from e2
        else:
            logger.error(f"无法自动修复依赖问题: {e}")
            raise RuntimeError(f"无法导入必要的模块，请尝试手动安装缺失的依赖") from e

# 导入配置
from . import config

def process_audio(tts_speeches, sample_rate=22050, format="wav"):
    """处理音频数据并返回字节流"""
    buffer = io.BytesIO()
    audio_data = torch.concat(tts_speeches, dim=1)
    torchaudio.save(buffer, audio_data, sample_rate, format=format)
    buffer.seek(0)
    return buffer

def load_voice_data(speaker):
    """加载语音数据"""
    voice_path = f"{config.VOICES_DIR}/{speaker}.pt"
    try:
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        if not os.path.exists(voice_path):
            return None
        voice_data = torch.load(voice_path, map_location=device)
        return voice_data.get('audio_ref')
    except Exception as e:
        logger.error(f"加载音色文件失败: {e}")
        raise ValueError(f"加载音色文件失败: {e}")

def get_available_voices() -> List[Dict[str, str]]:
    """获取所有可用的声音列表，包括预训练和自定义音色"""
    voices = []
    
    # 获取已有的 CosyVoice 模型
    tts_service = TTSService()
    
    # 获取预训练音色
    for name in tts_service.model.list_available_spks():
        voices.append({
            "name": name,
            "voice_id": name
        })
    
    # 获取自定义音色
    if os.path.exists(config.VOICES_DIR):
        for name in os.listdir(config.VOICES_DIR):
            if name.endswith('.pt'):
                voice_name = name.replace(".pt", "")
                voices.append({
                    "name": voice_name,
                    "voice_id": voice_name
                })
    
    return voices

class TTSService:
    _instance = None
    
    def __new__(cls):
        # 单例模式，确保模型只加载一次
        if cls._instance is None:
            cls._instance = super(TTSService, cls).__new__(cls)
            cls._instance.initialized = False
        return cls._instance
    
    def __init__(self):
        # 延迟初始化
        if not getattr(self, "initialized", False):
            self.initialize_model()
    
    def initialize_model(self):
        # 初始化模型
        try:
            logger.info("初始化CosyVoice2模型...")
            # 使用固定路径，与原Flask版本保持一致
            model_path = 'pretrained_models/CosyVoice2-0.5B'
            self.model = CosyVoice2(model_path)
            self.sample_rate = self.model.sample_rate
            self.default_voices = self.model.list_available_spks()
            
            self.spk_custom = []
            if os.path.exists(config.VOICES_DIR):
                for name in os.listdir(config.VOICES_DIR):
                    if name.endswith('.pt'):
                        self.spk_custom.append(name.replace(".pt", ""))
            
            logger.info(f"默认音色: {self.default_voices}")
            logger.info(f"自定义音色: {self.spk_custom}")
            self.initialized = True
        except Exception as e:
            logger.error(f"加载CosyVoice2失败: {str(e)}")
            
            # 尝试解决常见的错误
            if 'dateutil' in str(e):
                logger.info("尝试安装 python-dateutil...")
                if install_dependency("python-dateutil") and install_dependency("tn"):
                    logger.info("尝试重新初始化模型...")
                    try:
                        # 使用固定路径，与原Flask版本保持一致
                        model_path = 'pretrained_models/CosyVoice2-0.5B'
                        self.model = CosyVoice2(model_path)
                        self.sample_rate = self.model.sample_rate
                        self.default_voices = self.model.list_available_spks()
                        
                        self.spk_custom = []
                        if os.path.exists(config.VOICES_DIR):
                            for name in os.listdir(config.VOICES_DIR):
                                if name.endswith('.pt'):
                                    self.spk_custom.append(name.replace(".pt", ""))
                        
                        logger.info(f"默认音色: {self.default_voices}")
                        logger.info(f"自定义音色: {self.spk_custom}")
                        self.initialized = True
                        return
                    except Exception as e2:
                        logger.error(f"重新尝试加载CosyVoice2失败: {str(e2)}")
            
            # 尝试安装conformer模块
            if 'conformer' in str(e):
                logger.info("尝试安装 conformer...")
                if install_dependency("conformer") or install_dependency("git+https://github.com/sooftware/conformer.git"):
                    logger.info("尝试重新初始化模型...")
                    try:
                        # 使用固定路径
                        model_path = 'pretrained_models/CosyVoice2-0.5B'
                        self.model = CosyVoice2(model_path)
                        self.sample_rate = self.model.sample_rate
                        self.default_voices = self.model.list_available_spks()
                        
                        self.spk_custom = []
                        if os.path.exists(config.VOICES_DIR):
                            for name in os.listdir(config.VOICES_DIR):
                                if name.endswith('.pt'):
                                    self.spk_custom.append(name.replace(".pt", ""))
                        
                        logger.info(f"默认音色: {self.default_voices}")
                        logger.info(f"自定义音色: {self.spk_custom}")
                        self.initialized = True
                        return
                    except Exception as e2:
                        logger.error(f"重新尝试加载CosyVoice2失败: {str(e2)}")
            
            # 尝试安装diffusers模块
            if 'diffusers' in str(e):
                logger.info("尝试安装 diffusers...")
                if install_dependency("diffusers") and install_dependency("accelerate"):
                    logger.info("尝试重新初始化模型...")
                    try:
                        # 使用固定路径
                        model_path = 'pretrained_models/CosyVoice2-0.5B'
                        self.model = CosyVoice2(model_path)
                        self.sample_rate = self.model.sample_rate
                        self.default_voices = self.model.list_available_spks()
                        
                        self.spk_custom = []
                        if os.path.exists(config.VOICES_DIR):
                            for name in os.listdir(config.VOICES_DIR):
                                if name.endswith('.pt'):
                                    self.spk_custom.append(name.replace(".pt", ""))
                        
                        logger.info(f"默认音色: {self.default_voices}")
                        logger.info(f"自定义音色: {self.spk_custom}")
                        self.initialized = True
                        return
                    except Exception as e2:
                        logger.error(f"重新尝试加载CosyVoice2失败: {str(e2)}")
            
            # 如果所有尝试都失败了，抛出异常
            raise
    
    def generate_tts(self, 
                    text: str, 
                    speaker: str, 
                    instruct: Optional[str] = None,
                    streaming: bool = False,
                    speed: float = 1.0):
        """生成语音"""
        try:
            # 处理 instruct 模式
            if instruct:
                prompt_speech_16k = load_voice_data(speaker)
                if prompt_speech_16k is None:
                    raise ValueError("预训练音色文件中缺少audio_ref数据！")
                
                return self.model.inference_instruct2(
                    text, instruct, prompt_speech_16k, stream=streaming, speed=speed
                )
            else:
                return self.model.inference_sft(
                    text, speaker, stream=streaming, speed=speed
                )
        except Exception as e:
            logger.error(f"语音生成失败: {str(e)}")
            raise 