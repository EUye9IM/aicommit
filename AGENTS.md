# AI Commit Tool

Single-entrypoint bash script (`aicommit`) — no tests, CI, or build. Sourced in shell profile, not executed directly.

## Commands

```bash
# Stage and commit
git add <files>
aicommit

# Manual run
bash aicommit
```

## Architecture

- **Diff strategy**: Reads `git diff --cached` only, sorted by ascending diff size. Exits with "No changes to commit" if empty — **no fallback to unstaged diff**.
- **Diff truncation**: Hard limit of 5000 bytes. Files are added incrementally; once the cumulative diff exceeds the limit, remaining files are skipped. A secondary `head -c 5000` truncation acts as a safety net.
- **API**: Supports two modes via `LLM_API` env var: `response_stream` (default, OpenAI Responses API `/responses`) and `chat_stream` (OpenAI Chat Completions API `/chat/completions`). Payload constructed inline via `jq`.
- **Commit auto-executes**: `git commit -m "$commit_message"` is active — **not commented out**.
- **Prompt**: Chinese commit message with a title + optional body list. No markdown formatting symbols allowed in output.
- **Parameters** (`response_stream`): `temperature: 0`, `reasoning.effort: "low"`, `store: false`, `stream: true`. `chat_stream` mode omits `reasoning` field (not supported by that API).
- `set -f` at top disables glob expansion (relevant if filenames contain glob chars).

## Env Config

| Variable | Default | Note |
|---|---|---|
| `LLM_BASE_URL` | `http://localhost:1234/v1` | Path `/responses` is appended automatically |
| `LLM_AUTH_KEY` | (empty) | |
| `LLM_MODEL` | `gpt-3.5-turbo` | |
| `LLM_API` | `response_stream` | `response_stream` (Responses API) or `chat_stream` (Chat Completions API) |

## Dependencies

`curl`, `jq`, `git`, `wc`, `head` — all standard.

## Gotchas

- The script sources (via `.` or `source`) into the shell — it must produce output on stdout and NOT run commands that break the interactive shell.
- `curl` timeout: `MAXTIME=300` (5 minutes).
- Reasoning tokens are dimmed (`\033[90m`), final output is normal — the agent must NOT strip ANSI codes from the commit message variable.
- The script is in the repo root as `aicommit` (no `.sh` extension).
