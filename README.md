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
# 暂存文件后执行
git add .
aicommit

# 或直接运行（会自动使用 git diff）
aicommit
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `LLM_BASE_URL` | API 地址 | `http://localhost:1234/v1` |
| `LLM_AUTH_KEY` | API Key | 空 |
| `LLM_MODEL` | 模型名称 | `gpt-3.5-turbo` |

## 示例

配合 Ollama 本地模型使用：

```bash
export LLM_BASE_URL="http://localhost:11434/v1"
export LLM_AUTH_KEY=""
export LLM_MODEL="llama3"
```

## 依赖

- `curl`
- `git`
- `jq`（用于 JSON 构造）
- `wc`, `head`（系统自带）