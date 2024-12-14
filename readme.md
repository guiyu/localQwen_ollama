# Ollama Server - Windows本地部署方案

## 目录
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [目录结构](#目录结构)
- [详细安装步骤](#详细安装步骤)
- [功能模块](#功能模块)
- [运维指南](#运维指南)
- [故障排除](#故障排除)

## 系统要求

- Windows 10/11
- NVIDIA GPU (RTX 4070 或更高)
- Python 3.9+
- CUDA 11.7+
- 内存: 最小16GB，推荐32GB
- 存储: 最小100GB可用空间
- PowerShell 5.0+

## 快速开始

1. **初始化环境**
```batch
mkdir D:\ollama-server
cd D:\ollama-server
```

2. **安装服务**
```batch
scripts\install\install_all.bat
```

3. **测试服务**
```batch
scripts\test\test-sutra.bat
```

4. **查看分析报告**
```batch
python src\analysis\response_analyzer.py
```

## 目录结构

```
D:\ollama-server\
├── bin\                    # 可执行文件
│   ├── ollama.exe
│   └── ollama_service.exe
├── models\                 # 模型文件
│   └── qwen\
│       ├── modelfile
│       └── cache\
├── configs\                # 配置文件
│   ├── server.json
│   └── service.json
├── scripts\                # 脚本文件
│   ├── install\
│   ├── test\
│   └── utils\
├── logs\                   # 日志文件
│   ├── server\
│   └── models\
└── tools\                  # 工具程序
    ├── monitoring\
    └── maintenance\
```

## 详细安装步骤

### 1. 环境检查
```batch
scripts\utils\check_env.bat
```

### 2. 服务安装
```batch
scripts\install\setup_service.bat
```

### 3. 模型安装
```batch
scripts\install\setup_model.bat
```

### 4. 验证安装
```batch
scripts\test\test-api.bat
```

## 功能模块

### API 服务
- 基础对话能力
- 参数动态调整
- 上下文管理
- 并发请求处理

### 性能分析
- 响应时间统计
- GPU使用率监控
- 内存占用分析
- 吞吐量测试

### 运维工具
- 日志管理
- 缓存清理
- 性能监控
- 服务管理

## 运维指南

### 日常维护
```batch
# 查看服务状态
scripts\service\status.bat

# 清理缓存
scripts\utils\clean_cache.bat

# 监控GPU
tools\monitoring\gpu_monitor.bat
```

### 日志查看
```batch
# 服务日志
type logs\server\ollama.log

# 错误日志
type logs\server\error.log
```

### 性能监控
```batch
# GPU监控
python src\monitoring\gpu_monitor.py

# 性能分析
python src\analysis\response_analyzer.py
```

## 故障排除

### 常见问题解决

1. **服务无法启动**
   - 检查日志: `logs\server\error.log`
   - 检查GPU: `nvidia-smi`
   - 检查端口: `netstat -ano | findstr "11434"`

2. **模型加载失败**
   - 检查显存
   - 验证模型文件
   - 查看模型日志

3. **性能问题**
   - 检查GPU使用率
   - 监控内存占用
   - 分析响应时间

### 调试命令

```batch
# 检查环境
scripts\utils\check_env.bat

# 测试API
scripts\test\test-api.bat

# 性能测试
scripts\test\test-perf.bat
```

## 配置参考

### 服务配置
```json
{
    "server": {
        "host": "0.0.0.0",
        "port": 11434,
        "max_connections": 1000,
        "timeout": 30
    },
    "gpu": {
        "device": 0,
        "memory_limit": "10GB"
    }
}
```

### 模型配置
```yaml
FROM qwen:7b-chat

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1
PARAMETER num_ctx 2048

SYSTEM You are a helpful AI assistant.
```

## 注意事项

1. **资源管理**
   - 定期清理缓存
   - 监控显存使用
   - 管理日志大小

2. **安全建议**
   - 定期更新系统
   - 保护配置文件
   - 监控访问日志

3. **性能优化**
   - 适配GPU配置
   - 优化并发设置
   - 调整缓存策略