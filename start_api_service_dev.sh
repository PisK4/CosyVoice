#!/bin/bash
# CosyVoice2-Ex API服务启动脚本

# macOS fork安全设置
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# 激活Conda环境
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate cosyvoice

# 确保gunicorn已安装
pip install gunicorn

# 创建日志目录
mkdir -p logs

# 启动标识
echo "======================================"
echo "    启动 CosyVoice2-Ex API 服务"
echo "======================================"

# 检查启动模式
if [ "$1" == "dev" ]; then
    echo "以开发模式启动 (Flask 内置服务器)"
    python api.py
else
    echo "以生产模式启动 (Gunicorn WSGI 服务器)"
    # 检查是否需要后台运行
    if [ "$1" == "daemon" ]; then
        echo "作为守护进程在后台运行"
        nohup gunicorn -c gunicorn_config_dev.py wsgi:application > logs/startup.log 2>&1 &
        echo "服务已在后台启动，进程ID: $!"
        echo "查看日志请运行: tail -f logs/gunicorn_error.log"
    else
        echo "在前台运行服务"
        gunicorn -c gunicorn_config_dev.py wsgi:application
    fi
fi

echo "API 访问地址: http://localhost:9880" 