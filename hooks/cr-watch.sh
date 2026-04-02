#!/bin/bash

PR="${1:?Usage: cr-watch.sh <PR_NUMBER>}"
MAX_CHECKS="${CR_WATCH_MAX_CHECKS:-5}"
INTERVAL="${CR_WATCH_INTERVAL:-120}"
COUNT=0
PIDFILE="/tmp/cr-watch-${PR}.pid"

notify() {
  local title="$1" message="$2" sound="${3:-}"
  case "$(uname -s)" in
    Darwin)
      if [ -n "$sound" ]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
      else
        osascript -e "display notification \"$message\" with title \"$title\""
      fi
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        powershell.exe -Command "[void](New-Object -ComObject WScript.Shell).Popup('$message',5,'$title',64)" 2>/dev/null || true
      else
        notify-send "$title" "$message" 2>/dev/null || true
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      powershell.exe -Command "[void](New-Object -ComObject WScript.Shell).Popup('$message',5,'$title',64)" 2>/dev/null || true
      ;;
  esac
}

# Duplicate prevention (atomic mkdir as lock)
if ! mkdir "$PIDFILE.lock" 2>/dev/null; then
  exit 0
fi
echo $$ > "$PIDFILE"
rmdir "$PIDFILE.lock"
trap 'rm -f "$PIDFILE"' EXIT

while [ "$COUNT" -lt "$MAX_CHECKS" ]; do
  STATE=$(gh pr view "$PR" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")

  if [ "$STATE" = "UNKNOWN" ]; then
    sleep "$INTERVAL"
    continue
  fi

  if [ "$STATE" != "OPEN" ]; then
    notify "cr-watch終了" "PRがクローズされました"
    exit 0
  fi

  CR_STATUS=$(gh pr view "$PR" --json reviews \
    --jq '[.reviews[] | select(.author.login=="coderabbitai")] | last | .state // ""' 2>/dev/null || echo "")

  if echo "$CR_STATUS" | grep -qE 'APPROVED|CHANGES_REQUESTED'; then
    notify "CodeRabbit完了" "cr-fix を実行してください" "Glass"
    exit 0
  fi

  COUNT=$((COUNT + 1))
  sleep "$INTERVAL"
done
