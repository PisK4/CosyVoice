#!/bin/bash
# CosyVoice2-Ex FastAPI 开发环境快速启动脚本

# 获取当前目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# 设置环境变量
export PYTHONPATH=$SCRIPT_DIR:$PYTHONPATH
export COSYVOICE_API_PORT=9881  # 默认端口

# 为开发环境设置选项
export ENABLE_API_AUTH=false  # 开发环境禁用API认证
export PRELOAD_MODEL=true    # 开发环境不预加载模型

# 创建必要的目录
mkdir -p logs
mkdir -p voices
mkdir -p output
mkdir -p audios
mkdir -p api/prompts
mkdir -p api/audio

echo "===== CosyVoice2-Ex FastAPI 开发服务 ====="
echo "服务将在 http://localhost:9880 上启动"
echo "API 文档: http://localhost:9880/docs"
echo "开发模式: API验证已禁用，模型将在首次请求时加载"

# 检查并安装基本依赖
echo "检查关键依赖..."
if ! python -c "import fastapi" &> /dev/null; then
    echo "FastAPI 未安装，正在安装..."
    pip install fastapi uvicorn pydantic
fi

# 检查依赖安装脚本
if [ -f "api/setup_deps.py" ]; then
    echo "运行依赖检查和安装脚本..."
    python api/setup_deps.py
fi

# 启动服务
echo "正在启动 FastAPI 服务..."
python run-api.py 2>&1 | tee logs/api_dev_$(date +"%Y%m%d_%H%M%S").log

# 如果服务因错误退出，显示帮助信息
if [ $? -ne 0 ]; then
    echo "服务启动失败。请检查日志文件获取详细错误信息。"
    echo "常见问题排查:"
    echo "1. 依赖问题: 尝试运行 python api/setup_deps.py"
    echo "2. 端口占用: 尝试更改端口 export COSYVOICE_API_PORT=9882"
    echo "3. 查看详细排错指南: api/TROUBLESHOOTING.md"
fi 