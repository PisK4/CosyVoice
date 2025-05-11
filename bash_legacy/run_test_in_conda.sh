#!/bin/bash
# 在Conda环境中启动服务并运行测试

# 设置环境变量，确保API认证启用
export ENABLE_API_AUTH=true

# 清空先前的日志
echo > test_output.log

# 显示启动信息
echo "========================================"
echo "启动 FastAPI 服务并运行测试"
echo "========================================"

# 使用新的终端窗口启动服务
echo "在新窗口中启动服务..."
osascript -e 'tell application "Terminal" to do script "cd \"'"$(pwd)"'\" && ./start_fastapi_conda.sh --log-level debug"' &

# 等待服务启动
echo "等待服务启动 (30秒)..."
sleep 30

# 运行测试
echo "运行测试脚本..."
./test_fastapi.sh | tee test_output.log

# 显示完成信息
echo "测试完成，结果已保存到 test_output.log"
echo "服务继续在另一个终端窗口运行，请手动关闭" 