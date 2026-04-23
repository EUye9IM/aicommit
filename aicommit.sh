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

# if [ -z "$status_output" ]; then
# 	echo "No changes to commit"
# 	exit 1
# fi

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
	reasoning: {effort: "high"},store:false,temperature:0,stream:true}')
	thinking=0
	while IFS= read -r line; do
		case "$line" in
		event:*)
			# 提取事件类型，去除 prefix 和前后空白
			current_event="${line#event:}"
			current_event="${current_event#"${current_event%%[![:space:]]*}"}"
			;;
		data:*)
			# 提取数据内容，去除 prefix 和前后空白
			data_line="${line#data:}"
			data_line="${data_line#"${data_line%%[![:space:]]*}"}"
			# 累加 data 行（支持多行 data，用换行符连接）
			if [ -z "$data_accumulator" ]; then
				data_accumulator="$data_line"
			else
				data_accumulator="${data_accumulator}\n${data_line}"
			fi
			;;
		"")
			# 遇到空行表示一个事件结束
			if [ -n "$data_accumulator" ]; then
				event_name="${current_event}" # 默认事件名为 "message"
				# 根据 event 类型处理 JSON 字符串（$data_accumulator）
				case "$event_name" in
				response.reasoning_text.delta)
					if [[ $thinking -eq 0 ]]; then
						thinking=1
						echo -e "\033[90m"
					fi
					echo "$data_accumulator" | jq -rj '.delta'
					;;
				response.output_text.delta)
					if [[ $thinking -eq 1 ]]; then
						thinking=0
						echo -e "\033[0m"
					fi
					echo "$data_accumulator" | jq -rj '.delta'
					;;
				response.output_text.done)
					commit_message="$(
						echo "$data_accumulator" | jq -rj '.text'
					)"
					;;
				response.created | \
					response.in_progress | \
					response.output_item.added | \
					response.content_part.added | \
					response.content_part.done | \
					response.output_item.done | \
					response.reasoning_text.done | \
					response.completed)
					;;
				*)
					# echo "未处理的事件（$event_name）：$data_accumulator"
					;;
				esac
				# 重置当前事件状态
				current_event=""
				data_accumulator=""
			fi
			;;
		*)
			# 忽略 id:、retry: 等其他 SSE 字段
			;;
		esac
	done < <(curl -s -N --max-time $MAXTIME "${base_url%/}/responses" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $auth_key" \
		-d "$payload")
	;;
*)
	;;
esac

git commit -m "$commit_message"
