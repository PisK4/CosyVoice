#!/usr/bin/env python3
# CosyVoice2-Ex FastAPI 服务启动脚本

import os
import sys
import logging
import traceback
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('cosyvoice_api')

# 将当前目录添加到搜索路径
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append('{}/third_party/AcademiCodec'.format(ROOT_DIR))
sys.path.append('{}/third_party/Matcha-TTS'.format(ROOT_DIR))

def check_dependencies():
    """检查必要的依赖是否安装"""
    try:
        import torch
        import fastapi
        import uvicorn
        import pydantic
        logger.info(f"PyTorch版本: {torch.__version__}")
        logger.info(f"FastAPI版本: {fastapi.__version__}")
        logger.info(f"Uvicorn版本: {uvicorn.__version__}")
        return True
    except ImportError as e:
        logger.error(f"缺少必要的依赖: {str(e)}")
        logger.error("请运行: pip install -r requirements-api.txt")
        return False

def preload_model():
    """预加载模型，确保服务启动时模型已经加载"""
    try:
        # 创建logs目录
        os.makedirs("logs", exist_ok=True)
        
        # 保存当前时间作为日志文件名
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = f"logs/error_{timestamp}.log"
        
        from api.service import TTSService
        logger.info("预加载 CosyVoice2 模型...")
        service = TTSService()
        logger.info(f"模型加载成功! 可用的默认音色: {service.default_voices}")
        logger.info(f"自定义音色: {service.spk_custom}")
        return True
    except Exception as e:
        error_msg = f"模型预加载失败: {str(e)}"
        logger.error(error_msg)
        
        # 保存详细错误信息到日志文件
        with open(log_file, "w") as f:
            f.write(f"错误时间: {timestamp}\n")
            f.write(f"错误信息: {str(e)}\n")
            f.write(f"详细堆栈: {traceback.format_exc()}\n")
        
        logger.error(f"详细错误信息已保存到: {log_file}")
        
        # 显示解决方案提示
        logger.info("可能的解决方法:")
        logger.info("1. 检查模型文件是否存在于 pretrained_models/CosyVoice2-0.5B 目录")
        logger.info("2. 检查API依赖是否完整，尝试运行: pip install -r requirements-api.txt")
        logger.info("3. 检查是否有足够的系统资源（内存、GPU）")
        logger.info("4. 查看 api/TROUBLESHOOTING.md 获取更多故障排除方法")
        return False

def start_server():
    """启动FastAPI服务器"""
    from api.config import PORT, HOST
    import uvicorn
    
    logger.info(f"启动FastAPI服务器于 {HOST}:{PORT}")
    uvicorn.run(
        "api.main:app",
        host=HOST,
        port=PORT,
        log_level="info",
        reload=False
    )

if __name__ == "__main__":
    logger.info("======== CosyVoice2-Ex FastAPI 服务启动 ========")
    
    # 检查关键依赖
    if not check_dependencies():
        logger.error("依赖检查失败，服务无法启动")
        sys.exit(1)
    
    # 预加载模型（可选）
    try:
        from api.config import PRELOAD_MODEL
        if PRELOAD_MODEL:
            if not preload_model():
                logger.warning("模型预加载失败，服务将在请求时尝试加载模型")
    except (ImportError, AttributeError):
        logger.info("配置中未找到PRELOAD_MODEL选项，将在请求时加载模型")
    
    # 启动服务器
    start_server()