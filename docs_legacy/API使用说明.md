# CosyVoice2-Ex API 服务使用说明

## 1. 服务启动方式

CosyVoice2-Ex API 提供三种不同的启动方式，适合不同的使用场景：

### 1.1 开发模式（适合测试）

```bash
./start_api_service.sh dev
```

特点：
- 使用 Flask 内置开发服务器
- 单进程运行，适合调试
- 不适合生产环境

### 1.2 生产模式（前台运行）

```bash
./start_api_service.sh
```

特点：
- 使用 Gunicorn WSGI 服务器
- 多进程多线程处理请求
- 适合生产环境
- 前台运行，可直接查看日志

### 1.3 守护进程模式（后台运行）

```bash
./start_api_service.sh daemon
```

特点：
- 使用 Gunicorn WSGI 服务器
- 在后台运行，不占用终端
- 适合长期运行的生产环境
- 日志保存在 logs 目录

## 2. API 接口说明

### 2.1 文本转语音（TTS）

**接口地址**: `/tts` 或 `/`

**请求方式**: GET 或 POST

**请求参数**:

| 参数名 | 类型 | 必填 | 说明 |
|-------|-----|------|------|
| text | String | 是 | 需要转换的文本内容 |
| speaker | String | 是 | 使用的音色ID或名称 |
| instruct | String | 否 | 语音指令（用于特殊效果控制） |
| streaming | Integer | 否 | 是否使用流式输出（0:否, 1:是） |
| speed | Float | 否 | 语速倍率（默认1.0） |

**返回格式**:
- 成功：返回音频文件（wav 或 ogg 格式）
- 失败：返回 JSON 格式错误信息

**示例请求**:

```bash
# GET 请求示例
curl "http://localhost:9880/tts?text=你好，世界&speaker=舌尖上的中国" --output audio.wav

# POST 请求示例
curl -X POST "http://localhost:9880/tts" \
  -H "Content-Type: application/json" \
  -d '{"text":"你好，世界","speaker":"舌尖上的中国","speed":1.2}' \
  --output audio.wav
```

### 2.2 获取可用音色列表

**接口地址**: `/speakers`

**请求方式**: GET 或 POST

**返回格式**: JSON 数组，每个元素包含 name 和 voice_id

**示例请求**:

```bash
curl "http://localhost:9880/speakers"
```

**示例响应**:

```json
[
  {"name":"舌尖上的中国","voice_id":"舌尖上的中国"},
  {"name":"小说家","voice_id":"小说家"},
  {"name":"自定义音色1","voice_id":"自定义音色1"}
]
```

### 2.3 健康检查接口

**接口地址**: `/health`

**请求方式**: GET

**返回格式**: JSON

**示例请求**:

```bash
curl "http://localhost:9880/health"
```

**示例响应**:

```json
{"status":"healthy","service":"CosyVoice2-Ex API"}
```

## 3. 性能优化说明

当前 API 服务已进行以下优化：

1. **延迟加载模型**：应用启动时不立即加载模型，首次请求时才加载
2. **多进程处理**：使用 Gunicorn 多进程架构提高并发处理能力
3. **异步工作模式**：采用 gthread 工作模式支持异步请求处理
4. **超时调整**：针对语音生成耗时较长的特点进行了超时设置优化
5. **错误处理**：增强了错误处理和日志记录，提高稳定性

## 4. 注意事项

1. 首次请求会加载模型，响应时间较长
2. 长文本生成可能需要较长时间，请适当延长客户端超时设置
3. 流式输出模式适合生成较长语音内容，可提供更好的用户体验
4. 服务日志位于 logs 目录，可用于诊断问题

## 5. 故障排除

如果遇到问题，请检查：

1. 确认模型文件是否完整（位于 pretrained_models 目录）
2. 检查网络端口 9880 是否被占用
3. 查看日志文件 logs/gunicorn_error.log 了解详细错误
4. 尝试以开发模式启动，查看更详细的错误信息
5. 使用 `ps aux | grep gunicorn` 查看是否启动了程序在后台, 使用 `pkill -f gunicorn` 杀掉后台程序

如有其他问题，请联系支持团队。 