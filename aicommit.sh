#!/bin/bash
MAXSIZE=5000

base_url="${LLM_BASE_URL:-http://localhost:1234/v1}"
auth_key="${LLM_AUTH_KEY:-}"
model="${LLM_MODEL:-gpt-3.5-turbo}"

echo "=== LLM Configuration ==="
echo "Base URL: $base_url"
echo "Model: $model"
if [ -n "$auth_key" ]; then
	echo "API Key: ${auth_key:0:10}..." # Show only first 10 chars for security
else
	echo "API Key: (not set)"
fi
echo "========================="
echo ""

diff_output=$(git diff --cached 2>/dev/null)

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

prompt="根据以下 git diff 输出，用中文生成一个简洁的 git commit message（格式：类型：描述）。类型用 feat/fix/docs/style/refactor/test/chore 之一：\n\n${diff_output}"

payload=$(jq -n \
	--arg model "$model" \
	--arg prompt "$prompt" \
	'{model: $model, messages: [{role: "user", content: $prompt}], temperature: 0.2, "stream":false}')
echo
echo payload: "$(echo "$payload")"
echo
response=$(curl -s --max-time 60 "${base_url%/}/chat/completions" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $auth_key" \
	-d "$payload")
echo rsp: "$(echo "$response" | jq)"
echo
commit_message=$(echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | head -1)

if [ -z "$commit_message" ]; then
	echo "Failed to generate commit message"
	echo "Response: $response"
	exit 1
fi

echo "Generated commit message: $commit_message"
git commit -m "$commit_message"
