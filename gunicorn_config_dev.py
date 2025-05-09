#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
CosyVoice2-Ex API Gunicorn配置
"""
import os
import multiprocessing

# 绑定的IP和端口
bind = "0.0.0.0:9880"

workers = 1 

# 每个worker的线程数
threads = 4

# 工作进程类型 
worker_class = "sync"  # 使用同步模式，避免fork问题

# 超时设置（秒）- 由于模型推理可能需要较长时间，设置较长的超时
timeout = 300

# 处理请求的最大并发数
worker_connections = 1000

# 日志配置
loglevel = 'info'
accesslog = 'logs/gunicorn_access_dev.log'
errorlog = 'logs/gunicorn_error_dev.log'

# 确保日志目录存在
os.makedirs('logs', exist_ok=True)

# 预加载应用以减少启动延迟
preload_app = True

# 在加载应用后但接受连接前运行的回调函数
def on_starting(server):
    print("dev Gunicorn服务器正在启动...")

def post_fork(server, worker):
    """在fork worker后初始化模型"""
    from wsgi import application
    print(f"Worker {worker.pid}正在加载CosyVoice2模型...")
    application.initialize_model()
    print(f"Worker {worker.pid}已加载模型完成")

# 支持优雅重启
graceful_timeout = 120

# 保持活动连接超时
keepalive = 5

# 进程名称
proc_name = 'cosyvoice_api' 