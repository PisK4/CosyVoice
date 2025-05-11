#!/bin/bash
# CosyVoice2-Ex MacOS依赖安装脚本
# 用于解决torio库FFmpeg加载问题

echo "========================================"
echo "    MacOS 依赖安装助手"
echo "========================================"

# 检查Homebrew是否已安装
if ! command -v brew &> /dev/null; then
    echo "未找到Homebrew，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if ! command -v brew &> /dev/null; then
        echo "Homebrew安装失败，请手动安装后重试: https://brew.sh"
        exit 1
    fi
fi

echo "安装必要的系统库..."

# 安装FFmpeg和相关依赖
brew install ffmpeg libsndfile

# 创建软链接确保库能被找到
echo "创建必要的符号链接..."

# 检查是否是Apple Silicon芯片
if [[ $(uname -m) == 'arm64' ]]; then
    BREW_PREFIX="/opt/homebrew"
    PYTHON_LIB="/opt/homebrew/lib/python3.10/site-packages"
else
    BREW_PREFIX="/usr/local"
    PYTHON_LIB="/usr/local/lib/python3.10/site-packages"
fi

# 创建Python软链接指向系统库
if [ -d "$PYTHON_LIB" ]; then
    # 创建torchaudio的FFmpeg目录
    mkdir -p "$PYTHON_LIB/torchaudio/lib"
    
    # 链接FFmpeg库到torchaudio
    for lib in libavutil libavcodec libavformat libavfilter libswresample; do
        if [ -f "$BREW_PREFIX/lib/$lib"*.dylib ]; then
            LIBPATH=$(ls "$BREW_PREFIX/lib/$lib"*.dylib | head -1)
            ln -sf "$LIBPATH" "$PYTHON_LIB/torchaudio/lib/$lib.dylib" 2>/dev/null
            echo "已链接: $LIBPATH -> $PYTHON_LIB/torchaudio/lib/$lib.dylib"
        fi
    done
    
    # 链接libsndfile
    if [ -f "$BREW_PREFIX/lib/libsndfile"*.dylib ]; then
        LIBPATH=$(ls "$BREW_PREFIX/lib/libsndfile"*.dylib | head -1)
        ln -sf "$LIBPATH" "$PYTHON_LIB/torchaudio/lib/libsndfile.dylib" 2>/dev/null
        echo "已链接: $LIBPATH -> $PYTHON_LIB/torchaudio/lib/libsndfile.dylib"
    fi
else
    echo "警告: 未找到Python库目录 $PYTHON_LIB"
    echo "请手动将FFmpeg库链接到Python环境"
fi

# 设置环境变量
echo "设置环境变量..."
echo "export TORIO_FFMPEG_BINARY=ffmpeg" >> ~/.zshrc
echo "export DYLD_LIBRARY_PATH=$BREW_PREFIX/lib:\$DYLD_LIBRARY_PATH" >> ~/.zshrc

echo "========================================"
echo "依赖安装完成！"
echo "请重新启动终端或运行: source ~/.zshrc"
echo "然后重新启动API服务"
echo "========================================" 