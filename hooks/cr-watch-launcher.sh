#!/bin/bash

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
if ! echo "$COMMAND" | grep -qE '(^|\s|&&|\|)gh\s+pr\s+create(\s|$)'; then
  exit 0
fi

RESULT=$(echo "$INPUT" | jq -r '.tool_result // ""')
PR_NUMBER=$(echo "$RESULT" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+' | tail -1)

if [ -z "$PR_NUMBER" ]; then
  exit 0
fi

nohup "$HOME/.claude/hooks/cr-watch.sh" "$PR_NUMBER" > /dev/null 2>&1 &
