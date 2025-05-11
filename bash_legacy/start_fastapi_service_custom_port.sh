#!/bin/bash
# 启动 CosyVoice2-Ex FastAPI 服务，使用自定义端口

# 检查传入的端口参数
if [ -z "$1" ]; then
    PORT=9881  # 默认端口
else
    PORT=$1
fi

# 获取当前目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# 设置环境变量
export PYTHONPATH=$SCRIPT_DIR:$PYTHONPATH
export COSYVOICE_API_PORT=$PORT

# 创建日志目录
mkdir -p logs

# 检查必要的目录
mkdir -p voices
mkdir -p output
mkdir -p audios
mkdir -p api/prompts
mkdir -p api/audio

echo "启动 CosyVoice2-Ex FastAPI 服务..."
echo "使用 uvicorn 启动，端口: $PORT"

# 安装依赖
install_deps() {
    echo "安装基本依赖..."
    pip install -r requirements-api.txt
    
    # 检查并安装特定依赖
    install_package_if_missing() {
        if ! python -c "import $1" &> /dev/null; then
            echo "$1 未安装，尝试安装..."
            pip install $2
        else
            echo "$1 已安装"
        fi
    }
    
    # 检查基本依赖
    install_package_if_missing "modelscope" "modelscope>=1.11.0"
    install_package_if_missing "hyperpyyaml" "hyperpyyaml>=1.0.0"
    install_package_if_missing "inflect" "inflect>=6.0.0"
    install_package_if_missing "dateutil" "python-dateutil>=2.8.0"
    install_package_if_missing "tn" "tn>=0.0.4"
    install_package_if_missing "regex" "regex>=2022.0.0"
    install_package_if_missing "transformers" "transformers>=4.31.0"
    install_package_if_missing "omegaconf" "omegaconf>=2.0.0"
    
    # 检查 dateutil - 这是 tn 包的依赖
    if ! python -c "from dateutil import tz" &> /dev/null; then
        echo "python-dateutil 未安装或不完整，尝试安装..."
        pip install python-dateutil>=2.8.0
    else
        echo "python-dateutil 已安装"
    fi
    
    # 检查 whisper
    if ! python -c "import whisper" &> /dev/null; then
        echo "OpenAI Whisper 未安装，尝试安装..."
        pip install openai-whisper
    else
        echo "whisper 已安装"
    fi
    
    # 检查 onnxruntime
    # 根据系统类型自动选择合适的 onnxruntime 版本
    if ! python -c "import onnxruntime" &> /dev/null; then
        echo "onnxruntime 未安装，尝试安装..."
        
        # 检测当前系统信息
        if [[ "$(uname -m)" == "arm64" && "$(uname)" == "Darwin" ]]; then
            # macOS 上的 Apple Silicon
            echo "检测到 Apple Silicon Mac，安装 onnxruntime-silicon..."
            pip install onnxruntime-silicon || pip install onnxruntime
        elif python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
            # CUDA 可用
            echo "检测到 CUDA 环境，安装 onnxruntime-gpu..."
            pip install onnxruntime-gpu || pip install onnxruntime
        else
            # 默认情况
            echo "安装标准版 onnxruntime..."
            pip install onnxruntime
        fi
    else
        echo "onnxruntime 已安装"
    fi
    
    # 安装其他常见的依赖
    echo "安装其他常见依赖..."
    pip install pyyaml scipy matplotlib numba pandas scikit-learn regex transformers omegaconf

    # 安装特定版本的 numpy 以解决兼容性问题
    echo "确保 numpy 兼容性..."
    pip install 'numpy>=1.20.0,<2.0.0' --upgrade
}

# 安装可能缺少的其他依赖
install_missing_deps() {
    # 检查依赖问题的日志文件
    if [ -f ./logs/last_api_error.log ]; then
        # 查找 "No module named" 错误
        missing_modules=$(grep -o "No module named '[^']*'" ./logs/last_api_error.log | sed "s/No module named '\([^']*\)'/\1/g")
        
        for module in $missing_modules; do
            echo "尝试安装缺少的模块: $module"
            if [ "$module" == "dateutil" ]; then
                pip install python-dateutil
            elif [ "$module" == "ttsfrd" ]; then
                echo "ttsfrd 是内部模块，跳过安装尝试"
                # ttsfrd 一般是内部模块，无法通过 pip 安装，跳过
            elif [ "$module" == "tn.chinese" ] || [ "$module" == "tn.chinese.normalizer" ]; then
                echo "tn.chinese 模块将使用本地补丁替代，跳过安装尝试"
                # tn.chinese 通过本地补丁处理
            elif [ "$module" == "regex" ]; then
                pip install regex
            elif [ "$module" == "transformers" ]; then
                pip install transformers
            elif [ "$module" == "omegaconf" ]; then
                pip install omegaconf
            else
                pip install $module
            fi
        done
    fi
}

# 检查启动前的依赖
check_critical_deps() {
    # 确保关键依赖已安装，如果缺少则退出
    if ! python -c "import torch" &> /dev/null; then
        echo "错误: torch 未安装，这是运行 CosyVoice2 的必要依赖"
        echo "尝试运行: pip install torch"
        return 1
    fi
    
    if ! python -c "import fastapi" &> /dev/null; then
        echo "错误: fastapi 未安装，这是运行 API 服务的必要依赖"
        echo "尝试运行: pip install fastapi uvicorn"
        return 1
    fi
    
    # 检查其他关键依赖
    for module in regex transformers numpy omegaconf; do
        if ! python -c "import $module" &> /dev/null; then
            echo "错误: $module 未安装，这是运行 CosyVoice2 的必要依赖"
            echo "尝试运行: pip install $module"
            # 尝试自动安装
            pip install $module
        fi
    done
    
    return 0
}

# 函数用于检查端口是否被占用
check_port() {
    if command -v lsof >/dev/null 2>&1; then
        # 如果系统有 lsof 命令
        if lsof -i :$PORT | grep LISTEN >/dev/null; then
            echo "警告: 端口 $PORT 已被占用！"
            echo "1. 尝试使用不同的端口，例如: $0 9882"
            echo "2. 或者终止占用端口的进程后再次运行"
            return 1
        fi
    elif command -v netstat >/dev/null 2>&1; then
        # 如果系统有 netstat 命令
        if netstat -an | grep LISTEN | grep :$PORT >/dev/null; then
            echo "警告: 端口 $PORT 已被占用！"
            echo "1. 尝试使用不同的端口，例如: $0 9882"
            echo "2. 或者终止占用端口的进程后再次运行"
            return 1
        fi
    fi
    return 0
}

# 检查端口是否被占用
if ! check_port; then
    exit 1
fi

# 根据环境选择启动方式
if [ -d "venv" ]; then
    # 使用虚拟环境
    echo "使用虚拟环境..."
    source venv/bin/activate
    install_deps
    install_missing_deps
    
    if check_critical_deps; then
        python run-api.py 2>&1 | tee logs/api_$(date +"%Y%m%d_%H%M%S").log
    else
        echo "无法启动服务: 关键依赖缺失"
        exit 1
    fi
elif [ -n "$CONDA_PREFIX" ]; then
    # 使用 conda 环境
    echo "使用 conda 环境: $CONDA_PREFIX"
    install_deps
    install_missing_deps
    
    if check_critical_deps; then
        python run-api.py 2>&1 | tee logs/api_$(date +"%Y%m%d_%H%M%S").log
    else
        echo "无法启动服务: 关键依赖缺失"
        exit 1
    fi
else
    # 系统 Python
    echo "使用系统 Python: $(which python)"
    install_deps
    install_missing_deps
    
    if check_critical_deps; then
        python run-api.py 2>&1 | tee logs/api_$(date +"%Y%m%d_%H%M%S").log
    else
        echo "无法启动服务: 关键依赖缺失"
        exit 1
    fi
fi 