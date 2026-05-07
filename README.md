# AI Commit

使用 AI 生成 Git 提交信息的中文工具。

## 安装

1. 将脚本添加到你的 shell 配置文件：

```bash
# ~/.zshrc 或 ~/.bashrc
source /path/to/aicommit
```

2. 设置环境变量：

```bash
export LLM_BASE_URL="http://localhost:11434/v1" # OpenAI 兼容 API 地址
export LLM_AUTH_KEY="your-api-key" # API Key
export LLM_MODEL="gpt-3.5-turbo" # 使用的模型
```

## 使用

```bash
# 必须先暂存文件
git add <files>
aicommit
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `LLM_BASE_URL` | API 地址 | `http://localhost:1234/v1` |
| `LLM_AUTH_KEY` | API Key | 空 |
| `LLM_MODEL` | 模型名称 | `gpt-3.5-turbo` |
| `LLM_API` | API 类型：`response_stream`(Responses API) 或 `chat_stream`(Chat Completions API) | `response_stream` |

## 示例

### 配合 Ollama 本地模型

```bash
export LLM_BASE_URL="http://localhost:11434/v1"
export LLM_AUTH_KEY=""
export LLM_MODEL="llama3"
```

### 配合 OpenAI Chat Completions API（如 DeepSeek）

```bash
export LLM_BASE_URL="https://api.deepseek.com/v1"
export LLM_AUTH_KEY="your-api-key"
export LLM_MODEL="deepseek-chat"
export LLM_API="chat_stream"  # 使用 Chat Completions API
```

## 依赖

- `curl`
- `git`
- `jq`（用于 JSON 构造）
- `wc`, `head`（系统自带）