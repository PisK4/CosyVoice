#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
CosyVoice2 API WSGI入口点
用于生产环境部署，如Gunicorn、uWSGI等WSGI服务器
"""

import os
import sys
from api import create_app

# 创建应用实例 - 用于WSGI服务器
application = create_app()

# 如果直接运行此文件，则启动开发服务器（不推荐用于生产）
if __name__ == "__main__":
    print("警告：这是一个WSGI入口文件，应由WSGI服务器调用，不建议直接运行。")
    print("开发环境中，请使用: gunicorn -c gunicorn_config_dev.py wsgi:application")
    print("生产环境中，请使用: gunicorn -c gunicorn_config_prod.py wsgi:application")
    application.initialize_model()  # 确保模型加载
    application.run(host='0.0.0.0', port=9880, debug=False) 