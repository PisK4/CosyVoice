# CosyVoice2-Ex FastAPI 故障排除指南

本指南帮助你解决使用 CosyVoice2-Ex FastAPI 服务时可能遇到的常见问题。

## 依赖问题

### 1. 解决 ModuleNotFoundError 错误

如果你在启动服务或运行测试脚本时遇到类似以下错误：

```
ModuleNotFoundError: No module named 'conformer'
```

或者

```
ModuleNotFoundError: No module named 'diffusers'
```

或者

```
ModuleNotFoundError: No module named 'hydra'
```

或者

```
ModuleNotFoundError: No module named 'lightning'
```

**解决方法**:

1. 使用自动依赖安装脚本:
   ```bash
   python api/setup_deps.py
   ```

2. 手动安装缺失的模块:
   ```bash
   pip install conformer diffusers hydra-core lightning
   ```
   
3. 如果 pip 安装失败，尝试从源码安装:
   ```bash
   pip install git+https://github.com/sooftware/conformer.git
   pip install diffusers accelerate hydra-core lightning pytorch-lightning
   ```

### 2. 解决 dateutil 相关错误

如果遇到与 `dateutil` 或 `tn` 模块相关的错误:

```
ImportError: No module named 'dateutil'
```

**解决方法**:
```bash
pip install python-dateutil
pip install tn
```

### 3. 解决 onnxruntime 安装问题

如果 `onnxruntime` 安装失败或运行时出错:

**解决方法**:

- 对于 CPU-only 环境:
  ```bash
  pip install onnxruntime
  ```

- 对于 CUDA 环境:
  ```bash
  pip install onnxruntime-gpu
  ```

- 对于 Apple Silicon Mac:
  ```bash
  pip install onnxruntime-silicon
  ```

### 4. 特殊依赖 hyperpyyaml

如果遇到 `hyperpyyaml` 相关错误:

```
ModuleNotFoundError: No module named 'hyperpyyaml'
```

**解决方法**:
```bash
pip install hyperpyyaml
```

### 5. inflect 模块问题
```
ModuleNotFoundError: No module named 'inflect'
```

**解决方法**:
```bash
pip install inflect>=6.0.0
```

### 6. 出现 whisper 相关错误

```
ModuleNotFoundError: No module named 'whisper'
```

**解决方法**:
```bash
pip install openai-whisper
```

### 7. hydra 模块问题

```
ModuleNotFoundError: No module named 'hydra'
```

这是 flow_matching 组件需要的模块。

**解决方法**:
```bash
pip install hydra-core omegaconf
```

### 8. lightning 模块问题

```
ModuleNotFoundError: No module named 'lightning'
```

这是 Matcha-TTS 组件需要的模块。

**解决方法**:
```bash
pip install lightning pytorch-lightning
```

### 9. 依赖链问题

某些模块依赖于其他模块，如果遇到依赖链问题，一次性安装所有关键依赖:

```bash
pip install torch torchaudio numpy scipy transformers diffusers accelerate conformer hydra-core lightning pytorch-lightning
```

## 运行时问题

### 1. 服务无法启动

如果 API 服务无法启动，可能是以下原因:

- **端口被占用**：默认端口是 9881，确保没有其他应用占用此端口
  ```bash
  # 检查端口占用
  lsof -i :9881
  # 使用其他端口启动
  export COSYVOICE_API_PORT=9882
  ./start_fastapi_service.sh
  ```

- **Python 路径问题**：确保当前目录在 Python 路径中
  ```bash
  export PYTHONPATH=$PWD:$PYTHONPATH
  ```

- **权限问题**：确保启动脚本有执行权限
  ```bash
  chmod +x start_fastapi_service.sh
  ```

### 2. 模型加载失败

如果模型加载失败，可能是以下原因:

- **模型文件缺失**：检查 `pretrained_models/CosyVoice2-0.5B` 目录是否存在所有模型文件
  ```bash
  # 检查模型目录
  ls -la pretrained_models/CosyVoice2-0.5B
  ```

- **内存不足**：尝试在更大内存的环境中运行，或减少其他应用程序的内存使用

- **GPU问题**：如果使用 GPU，确保 CUDA 环境正确配置
  ```bash
  # 检查 CUDA 可用性
  python -c "import torch; print(torch.cuda.is_available())"
  ```

### 3. API 认证失败

如果 API 请求返回 401 未授权错误:

- 确保在请求头中包含了正确的 API 密钥:
  ```
  X-API-Key: cosyvoice-api-demo
  ```

- 检查 `config.py` 中的 `API_KEYS` 列表是否包含你的密钥

- 如果不需要认证，可以在环境变量中禁用:
  ```bash
  export ENABLE_API_AUTH=false
  ```

## 调试方法

### 1. 开启详细日志

- 日志文件位于 `logs/` 目录，查看最新的日志:
  ```bash
  tail -f logs/api_*.log
  ```

### 2. 使用健康检查

- 检查 API 服务是否正常运行:
  ```bash
  curl http://localhost:9881/health
  ```

### 3. 测试 API 连接性

- 使用测试脚本:
  ```bash
  python api/test_api.py --url http://localhost:9881 --key cosyvoice-api-demo
  ```

- 不使用认证:
  ```bash
  python api/test_api.py --url http://localhost:9881 --no-auth
  ```

## 常见错误和解决方案

### 1. TypeError: Object of type Tensor is not JSON serializable
这通常发生在尝试直接返回 PyTorch 张量时。

**解决方法**:
- 在 API 代码中确保所有返回到 JSON 响应的数据都已转换为 Python 原生类型。

### 2. RuntimeError: CUDA out of memory
GPU 内存不足，无法加载模型。

**解决方法**:
- 减少批处理大小或使用 CPU 模式:
  ```bash
  # 强制使用 CPU
  export CUDA_VISIBLE_DEVICES=""
  ```

### 3. ConnectionRefusedError: [Errno 111] Connection refused
无法连接到 API 服务。

**解决方法**:
- 确保 API 服务正在运行
- 检查 URL 和端口是否正确
- 检查防火墙设置

## 其他提示

- **缓存清理**: 如果模型加载异常，尝试清理 Hugging Face 缓存:
  ```bash
  rm -rf ~/.cache/huggingface/
  ```

- **虚拟环境**: 使用虚拟环境隔离依赖:
  ```bash
  python -m venv venv
  source venv/bin/activate
  ```

- **依赖版本锁定**: 如果遇到依赖冲突，使用特定版本:
  ```bash
  pip install numpy==1.24.3
  ```

如果你遇到的问题未在本指南中列出，请检查日志文件获取更多详细信息，或向项目维护者报告问题。 