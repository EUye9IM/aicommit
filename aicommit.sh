#!/bin/bash
base_url="${LLM_BASE_URL:-http://localhost:1234/v1}"
auth_key="${LLM_AUTH_KEY:-}"
model="${LLM_MODEL:-gpt-3.5-turbo}"

set -f

MAXSIZE=5000
MAXTIME=300
API=response_stream

diff_output="$(git diff --cached 2>/dev/null)"
status_output="$(git status --short)"

if [ -z "$diff_output" ]; then
	diff_output=$(git diff 2>/dev/null)
fi

if [ -z "$diff_output" ]; then
	echo "No changes to commit"
	exit 1
fi

if [ "$(echo "$diff_output" | wc -c)" -gt $MAXSIZE ]; then
	diff_output=$(echo "$diff_output" | head -c $MAXSIZE)
	echo "Warning: diff truncated to 10000 bytes"
fi

prompt="
根据以下 git status 和 git diff 输出，中文生成一个简洁的 git commit message。
要求：
	1. 使用中文。
	2. 有一个简短的标题和一些内容
	3. 标题和内容之间存在一个空行
	4. 移除所有格式符号，不要携带'*','**','\`'等符号

status:
\`\`\`
${status_output}
\`\`\`

diff:
\`\`\`
${diff_output}
\`\`\`
"

echo "=== LLM Configuration ==="
echo "Base URL: $base_url"
echo "Model: $model"
if [ -n "$auth_key" ]; then
	echo "API Key: ${auth_key:0:10}..." # Show only first 10 chars for security
else
	echo "API Key: (not set)"
fi
echo "API: $API"
echo "========================="
echo ""

echo Generating...
commit_message=""
case "$API" in
response_stream)
	payload=$(jq -n -c \
		--arg model "$model" \
		--arg prompt "$prompt" \
		'{model: $model, input: [{role: "user", content: $prompt}],
	reasoning: {effort: "high"},store:false,temperature:0}')
	while IFS= read -r line; do
		echo $line
	done < <(curl -s -N --max-time $MAXTIME "${base_url%/}/responses" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $auth_key" \
		-d "$payload")
	;;
*)
	;;
esac

# git commit -m "$commit_message"
