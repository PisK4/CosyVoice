#!/bin/bash
# CosyVoice2-Ex API修复启动脚本

# 获取当前目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# 默认配置
API_PORT=9881
PRELOAD_MODEL=true
LOG_LEVEL="info"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)
      API_PORT="$2"
      shift 2
      ;;
    --no-preload)
      PRELOAD_MODEL=false
      shift
      ;;
    --log-level)
      LOG_LEVEL="$2"
      shift 2
      ;;
    --help)
      echo "用法: $0 [--port 端口号] [--no-preload] [--log-level 日志级别]"
      echo ""
      echo "选项:"
      echo "  --port <端口号>    指定 API 端口 (默认: 9881)"
      echo "  --no-preload       禁用模型预加载 (提高启动速度，但首次请求较慢)"
      echo "  --log-level <级别> 指定日志级别 (debug, info, warning, error) (默认: info)"
      echo "  --help             显示此帮助信息"
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      echo "用法: $0 [--port 端口号] [--no-preload] [--log-level 日志级别] [--help]"
      exit 1
      ;;
  esac
done

# 显示启动信息
echo "========================================"
echo "CosyVoice2-Ex API 服务启动器 (修复版)"
echo "========================================"
echo "API 端口: $API_PORT"
echo "模型预加载: $PRELOAD_MODEL"
echo "日志级别: $LOG_LEVEL"
echo "服务地址: http://localhost:$API_PORT"
echo "API 文档: http://localhost:$API_PORT/docs"
echo "========================================"

# 检查系统平台
if [[ "$(uname)" == "Darwin" ]]; then
    echo "检测到 macOS 系统"
    
    # 检查FFmpeg是否已安装
    if ! command -v ffmpeg &> /dev/null; then
        echo "警告: 未安装FFmpeg，这可能导致语音处理失败"
        echo "运行安装脚本: ./api/install_deps_macos.sh"
        
        read -p "是否立即安装FFmpeg? (y/n) " install_ffmpeg
        if [[ $install_ffmpeg == "y" || $install_ffmpeg == "Y" ]]; then
            ./api/install_deps_macos.sh
        else
            echo "您选择了不安装FFmpeg，这可能会导致服务无法正常工作"
        fi
    else
        echo "FFmpeg已安装: $(ffmpeg -version | head -n 1)"
    fi
    
    # 设置必要的环境变量
    export TORIO_FFMPEG_BINARY=ffmpeg
    export TORIO_USE_FFMPEG=0
    export TORIO_NO_FFMPEG=1
    
    # macOS上需要设置动态库路径
    if [[ "$(uname -m)" == "arm64" ]]; then
        export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"
    else
        export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"
    fi
elif [[ "$(uname)" == "Linux" ]]; then
    echo "检测到 Linux 系统"
    
    # 检查FFmpeg是否已安装
    if ! command -v ffmpeg &> /dev/null; then
        echo "警告: 未安装FFmpeg，这可能导致语音处理失败"
        echo "请使用系统包管理器安装FFmpeg，例如:"
        echo "Ubuntu/Debian: sudo apt-get install ffmpeg"
        echo "CentOS/RHEL: sudo yum install ffmpeg"
        
        read -p "是否尝试自动安装FFmpeg? (y/n) " install_ffmpeg
        if [[ $install_ffmpeg == "y" || $install_ffmpeg == "Y" ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y ffmpeg libsndfile1
            elif command -v yum &> /dev/null; then
                sudo yum install -y ffmpeg libsndfile
            else
                echo "无法自动安装，请手动安装FFmpeg后重试"
                exit 1
            fi
        else
            echo "您选择了不安装FFmpeg，这可能会导致服务无法正常工作"
        fi
    else
        echo "FFmpeg已安装: $(ffmpeg -version | head -n 1)"
    fi
    
    # 设置环境变量
    export TORIO_FFMPEG_BINARY=ffmpeg
    export TORIO_USE_FFMPEG=0
else
    echo "不支持的操作系统: $(uname)"
    echo "本脚本目前只支持 macOS 和 Linux"
    exit 1
fi

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p logs
mkdir -p voices
mkdir -p output
mkdir -p audios
mkdir -p api/prompts
mkdir -p api/audio

# 设置环境变量
export PYTHONPATH=$SCRIPT_DIR:$PYTHONPATH
export COSYVOICE_API_PORT=$API_PORT

# 明确显示预加载状态
if [ "$PRELOAD_MODEL" = "true" ]; then
    echo "配置预加载模型: 开启"
    export PRELOAD_MODEL="True"  # 大写T
else
    echo "配置预加载模型: 关闭"
    export PRELOAD_MODEL="False"  # 大写F
fi

# 额外调试输出
echo "环境变量设置:"
echo "PRELOAD_MODEL=$PRELOAD_MODEL"
echo "PYTHONPATH=$PYTHONPATH"
echo "COSYVOICE_API_PORT=$COSYVOICE_API_PORT"

export COSYVOICE_DEBUG=1  # 启用调试模式

# 创建日志目录
LOG_FILE="logs/api_$(date +"%Y%m%d_%H%M%S").log"
echo "日志将保存到: $LOG_FILE"

# 激活conda环境，如果存在
CONDA_ENV="cosyvoice"
if command -v conda &> /dev/null; then
    echo "检测到 conda，尝试激活环境: $CONDA_ENV"
    source "$(conda info --base)/etc/profile.d/conda.sh"
    if conda env list | grep -q "^$CONDA_ENV "; then
        conda activate $CONDA_ENV
        echo "已激活 conda 环境: $CONDA_ENV"
    else
        echo "警告: conda 环境 $CONDA_ENV 不存在，将使用当前 Python 环境"
    fi
else
    echo "未检测到 conda，将使用当前 Python 环境"
fi

# 检查依赖
echo "检查基本依赖..."
python -c "
try:
    import fastapi, uvicorn, torch, numpy
    print('基本依赖检查通过')
except ImportError as e:
    print(f'错误: 缺少依赖: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "缺少基本依赖，请安装后重试"
    echo "pip install fastapi uvicorn torch numpy"
    exit 1
fi

# 启动 FastAPI 服务
echo "启动 FastAPI 服务..."
python -c "
import os
import sys
import logging
import uvicorn

# 配置日志
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('$LOG_FILE')
    ]
)

logger = logging.getLogger('cosyvoice_api')

# 启动服务
logger.info('启动 FastAPI 服务')

try:
    uvicorn.run(
        'api.main:app',
        host='0.0.0.0',
        port=$API_PORT,
        log_level='$LOG_LEVEL'
    )
except Exception as e:
    logger.error(f'启动服务出错: {str(e)}')
    sys.exit(1)
"

echo "服务已停止。查看日志文件获取详细信息: $LOG_FILE" 