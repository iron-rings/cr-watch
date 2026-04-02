#!/bin/bash
set -euo pipefail

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Check dependencies
for cmd in gh jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required. Install it first." >&2
    exit 1
  fi
done

# 2. Create hooks directory
mkdir -p "$HOOKS_DIR"

# 3. Copy hook files
cp "$SCRIPT_DIR/hooks/"* "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/"*.sh

# 4. Merge settings.json
[ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak"
if [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" << 'ENDJSON'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type":"command","command":"~/.claude/hooks/cr-watch-launcher.sh","statusMessage":""}]
      }
    ]
  }
}
ENDJSON
elif jq -e '.hooks.PostToolUse[]?.hooks[]? | select(.command | contains("cr-watch-launcher"))' "$SETTINGS" >/dev/null 2>&1; then
  echo "cr-watch hook already registered. Skipping settings.json."
elif jq -e '.hooks.PostToolUse' "$SETTINGS" >/dev/null 2>&1; then
  jq '.hooks.PostToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"~/.claude/hooks/cr-watch-launcher.sh","statusMessage":""}]}]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
else
  jq '.hooks.PostToolUse = [{"matcher":"Bash","hooks":[{"type":"command","command":"~/.claude/hooks/cr-watch-launcher.sh","statusMessage":""}]}]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
fi

echo "✅ cr-watch installed. CodeRabbit review notifications are now active."
