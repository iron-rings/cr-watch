#!/bin/bash
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

rm -f "$HOOKS_DIR/cr-watch.sh" "$HOOKS_DIR/cr-watch.ps1"
rm -f "$HOOKS_DIR/cr-watch-launcher.sh" "$HOOKS_DIR/cr-watch-launcher.ps1"

if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  jq '.hooks.PostToolUse = [.hooks.PostToolUse[]? | select(.hooks[]?.command | contains("cr-watch-launcher") | not)]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
fi

echo "✅ cr-watch uninstalled."
