# OpenCode Instructions for AI Commit Tool

## Architecture Overview

Simple bash script project with a single entrypoint: **`aicommit.sh`**. No tests, CI/CD, or build process.

## Essential Commands

```bash
# Run the tool (must stage changes first or it falls back to unstaged)
git add <files>
aicommit

# Manual verification
bash aicommit.sh
```

## Environment Configuration

All variables have defaults - override them in your shell profile:

- `LLM_BASE_URL`: OpenAI-compatible API endpoint (default: `http://localhost:1234/v1`)
- `LLM_AUTH_KEY`: API key for authentication (default: empty)
- `LLM_MODEL`: Model name (default: `gpt-3.5-turbo`)

Example for Ollama local:
```bash
export LLM_BASE_URL="http://localhost:11434/v1"
export LLM_AUTH_KEY=""
export LLM_MODEL="llama3"
```

## Execution Flow

1. **Fallthrough diff strategy**: Checks `git diff --cached` first, then falls back to `git diff` if no staged changes
2. **Diff truncation**: Automatically truncates diffs to 10000 bytes with a warning
3. **API parameters**: Temperature is hardcoded to `0.2` for consistent output
4. **Commit generation**: Generates Chinese commit messages in format `类型：描述` (type: description)
5. **Dry-run mode**: The final `git commit -m` command is **commented out** (line 45) - must manually uncomment for auto-commit

## Dependencies

- `git`, `curl`, `jq` (for JSON construction), `grep`, `sed`

## Code Generation Notes

- `payload.json`: This file appears to be an example/payload template but **is not used by the script**. The script constructs its own JSON payload using `jq` inline.
- When modifying the API call, edit the `payload=$(jq -n ...)` construction directly in `aicommit.sh`
