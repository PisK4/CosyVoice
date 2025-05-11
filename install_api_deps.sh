#!/bin/bash
# CosyVoice2-Ex API 一键安装所有依赖

# 设置彩色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== CosyVoice2-Ex API 依赖安装脚本 =====${NC}"
echo -e "${YELLOW}本脚本将安装所有必要的依赖以运行FastAPI服务${NC}"

# 安装基础依赖
echo -e "\n${BLUE}安装基础API依赖...${NC}"
pip install fastapi uvicorn pydantic python-multipart

# 安装核心依赖
echo -e "\n${BLUE}安装CosyVoice2核心依赖...${NC}"
pip install torch torchaudio
pip install numpy scipy
pip install transformers modelscope
pip install diffusers accelerate
pip install onnxruntime

# 安装特殊依赖
echo -e "\n${BLUE}安装特殊依赖...${NC}"
pip install conformer || pip install git+https://github.com/sooftware/conformer.git
pip install hyperpyyaml
pip install inflect
pip install python-dateutil
pip install tn
pip install regex
pip install pyyaml

# 安装其他有用工具
echo -e "\n${BLUE}安装其他工具...${NC}"
pip install matplotlib numba pandas scikit-learn

# 检查是否有Mac特殊依赖
if [[ "$(uname)" == "Darwin" ]]; then
    echo -e "\n${BLUE}检测到Mac系统，安装特定依赖...${NC}"
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo -e "${YELLOW}检测到Apple Silicon，尝试安装onnxruntime-silicon...${NC}"
        pip install onnxruntime-silicon || pip install onnxruntime
    fi
fi

# 运行测试
echo -e "\n${GREEN}依赖安装完成！${NC}"
echo -e "${YELLOW}现在运行依赖检查脚本验证安装...${NC}"
python api/setup_deps.py

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}所有依赖安装成功！${NC}"
    echo -e "${YELLOW}你现在可以运行以下命令启动API服务：${NC}"
    echo -e "${BLUE}./start_fastapi_service_dev.sh${NC}"
else
    echo -e "\n${RED}依赖安装过程中出现错误，请查看上面的错误信息${NC}"
    echo -e "${YELLOW}你可以尝试手动安装缺失的依赖${NC}"
    echo -e "${YELLOW}参考故障排除指南：api/TROUBLESHOOTING.md${NC}"
    exit 1
fi 