# FFmpeg 依赖问题排查指南

## 问题描述

在启动 CosyVoice2-Ex API 服务时，可能会遇到以下错误：

```
Failed to load FFmpeg6 extension.
...
OSError: dlopen(...): Library not loaded: @rpath/libavutil.58.dylib
```

这表明系统无法找到 FFmpeg 相关的动态库，导致 torio 音频处理库无法正常工作。

## 解决方案

### 方法 1: 使用修复版的启动脚本

最简单的方法是使用已修复的启动脚本 `start_api_fixed.sh`，它会自动处理 FFmpeg 依赖问题：

```bash
# 默认端口 9881
./start_api_fixed.sh

# 使用自定义端口
./start_api_fixed.sh --port 9882

# 禁用模型预加载
./start_api_fixed.sh --no-preload
```

### 方法 2: 为 macOS 系统安装依赖

macOS 用户可以运行专门的依赖安装脚本：

```bash
# 安装 FFmpeg 依赖
./api/install_deps_macos.sh

# 然后使用修复版启动脚本
./start_api_fixed.sh
```

### 方法 3: 手动设置环境变量

如果上述方法不起作用，可以尝试手动设置环境变量：

```bash
# 指定使用系统的 FFmpeg
export TORIO_FFMPEG_BINARY=ffmpeg

# 禁用 torio 内置的 FFmpeg 加载机制
export TORIO_USE_FFMPEG=0
export TORIO_NO_FFMPEG=1

# 设置动态库搜索路径 (macOS)
export DYLD_LIBRARY_PATH=/usr/local/lib:/opt/homebrew/lib:$DYLD_LIBRARY_PATH

# 然后启动服务
./start_fastapi_conda.sh
```

### 方法 4: 安装 FFmpeg

确保系统已安装 FFmpeg：

#### macOS:

```bash
# 使用 Homebrew 安装
brew install ffmpeg libsndfile
```

#### Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y ffmpeg libsndfile1
```

#### CentOS/RHEL:

```bash
sudo yum install -y ffmpeg libsndfile
```

## 技术原因

问题的根本原因是 `torio` 库尝试加载内置的 FFmpeg 库，但这些库依赖于系统中的其他动态库（如 `libavutil.*.dylib`）。当这些依赖库找不到时，加载失败。

我们的修复方法是：

1. 设置环境变量，让 `torio` 使用系统安装的 FFmpeg 而不是内置版本
2. 在 macOS 上设置正确的动态库搜索路径
3. 在代码中捕获并优雅地处理 FFmpeg 加载错误

## 预加载模型问题

预加载模型功能受到 FFmpeg 依赖问题的影响。修复 FFmpeg 问题后，预加载功能也会正常工作。如果仍然遇到问题，可以先使用 `--no-preload` 选项禁用预加载，然后通过首次请求触发模型加载。 