# CosyVoice2-Ex FastAPI 服务

本目录包含 CosyVoice2-Ex 的 FastAPI 实现，提供高性能、易于使用的 REST API 接口，用于文本转语音 (TTS) 服务。

## 功能特点

- 高性能：基于 FastAPI 和 Uvicorn 的异步处理
- 易于部署：自动依赖检查和安装
- 详细文档：自动生成的 OpenAPI 文档
- 安全：支持 API 密钥认证
- 灵活：支持 GET 和 POST 请求方式
- 兼容性：与原有 Flask 版本保持 API 接口一致

## 目录结构

```
api/
├── config.py           # 配置文件
├── main.py             # FastAPI 主应用
├── service.py          # TTS 服务实现
├── tn_patch.py         # TN 模块补丁（解决依赖问题）
├── README.md           # 本文档
└── TROUBLESHOOTING.md  # 故障排除指南
```

## 快速开始

### 启动服务

使用提供的脚本启动服务：

```bash
# 默认端口 9881
./start_fastapi_service.sh

# 使用自定义端口
./start_fastapi_service_custom_port.sh 9882
```

服务启动后，可以通过以下地址访问：

- API 端点: http://localhost:9881/
- API 文档: http://localhost:9881/docs
- API 说明: http://localhost:9881/redoc

### 测试 API

使用提供的测试脚本：

```bash
# 基本测试
./test_fastapi.sh

# 更详细的 Python 测试
python test_fastapi_tts.py --list-speakers
python test_fastapi_tts.py --text "你好，世界" --speaker "zh_F_1"
```

## API 接口说明

### 1. 文本转语音 (GET)

```
GET /tts?text={text}&speaker={speaker_id}&instruct={instruct}&streaming={0|1}&speed={1.0}
```

参数：
- `text`：需要转换的文本（必填）
- `speaker`：音色 ID（必填）
- `instruct`：指令，控制语音风格（可选）
- `streaming`：是否流式输出，0 表示否，1 表示是（可选，默认 0）
- `speed`：语速，范围 0.5-2.0（可选，默认 1.0）

头部信息：
- `X-API-Key`：API 密钥（如果启用了认证）

### 2. 文本转语音 (POST)

```
POST /tts
```

请求体（JSON）：
```json
{
  "text": "需要转换的文本",
  "speaker": "音色ID",
  "instruct": "用开心的语气说",  // 可选
  "streaming": false,         // 可选，默认 false
  "speed": 1.0                // 可选，默认 1.0
}
```

头部信息：
- `Content-Type: application/json`
- `X-API-Key`：API 密钥（如果启用了认证）

### 3. 获取音色列表

```
GET /speakers
```

响应（JSON）：
```json
[
  {
    "name": "音色名称",
    "voice_id": "音色ID"
  },
  ...
]
```

### 4. 健康检查

```
GET /health
```

响应（JSON）：
```json
{
  "status": "healthy",
  "service": "CosyVoice2-Ex API"
}
```

## 配置选项

API 配置可以通过环境变量控制：

- `COSYVOICE_API_PORT`：API 端口（默认 9881）
- `ENABLE_API_AUTH`：是否启用 API 认证（默认 True）

配置文件 `api/config.py` 可以修改更多高级选项。

## 认证说明

默认启用 API 认证。请在请求头中添加 `X-API-Key` 字段，使用有效的 API 密钥。
默认可用的 API 密钥为 `cosyvoice-api-demo`。

可以通过设置环境变量禁用认证：
```bash
export ENABLE_API_AUTH=False
```

## 故障排除

如果遇到问题，请参考 [故障排除指南](TROUBLESHOOTING.md)。

常见问题包括：
- 缺少依赖模块
- 端口被占用
- 模型加载失败
- API 认证错误

## 与 Flask 版本的区别

FastAPI 版本与 Flask 版本保持 API 接口一致，但有以下改进：

1. 性能更好：基于 ASGI 的异步处理
2. 自动文档：更详细的 OpenAPI 自动生成文档
3. 更好的依赖管理：自动检查和安装缺失依赖
4. 更强的错误处理：更详细的错误信息和日志
5. 更完善的请求验证：基于 Pydantic 模型
6. 支持自定义端口和认证配置 