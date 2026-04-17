#!/bin/bash

git_aicommit() {
	local base_url="${LLM_BASE_URL:-http://localhost:11434/v1}"
	local auth_key="${LLM_AUTH_KEY:-}"
	local model="${LLM_MODEL:-gpt-3.5-turbo}"
	local diff_output
	local commit_message
	local prompt
	local response
	local payload

	diff_output=$(git diff --cached 2>/dev/null)

	if [ -z "$diff_output" ]; then
		diff_output=$(git diff 2>/dev/null)
	fi

	if [ -z "$diff_output" ]; then
		echo "No changes to commit"
		return 1
	fi

	prompt="根据以下 git diff 输出，用中文生成一个简洁的 git commit message（50 字以内，格式：类型：描述）。类型用 feat/fix/docs/style/refactor/test/chore 之一：\n\n${diff_output}"

	payload=$(jq -n \
		--arg model "$model" \
		--arg prompt "$prompt" \
		'{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: 256, temperature: 0.7}')
	echo "$payload"
	curl -s --max-time 60 "${base_url%/}/chat/completions" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $auth_key" \
		-d "$payload"
	response=$(curl -s --max-time 60 "${base_url%/}/chat/completions" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $auth_key" \
		-d "$payload")

	commit_message=$(echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | head -1)

	if [ -z "$commit_message" ]; then
		echo "Failed to generate commit message"
		echo "Response: $response"
		return 1
	fi

	echo "Generated commit message: $commit_message"
	git commit -m "$commit_message"
}

alias aicommit='git_aicommit'
