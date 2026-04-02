# cr-watch

Claude CodeでPR作成後、CodeRabbitのレビュー完了を自動検知してデスクトップ通知を送るツールです。

## 概要

cr-watchは以下の流れで動作します：

1. Claude CodeでPRを作成（`gh pr create`実行）
2. インストール済みのhookが自動発火
3. 定期的にCodeRabbitのレビュー状態をチェック（2分おき、最大10分）
4. CodeRabbitのレビューが完了したら自動検知
5. デスクトップ通知を送信
6. ユーザーが `/cr-fix` を手動実行

```
gh pr create → hook自動発火 → 2分おきにチェック(最大10分) → CodeRabbit完了 → デスクトップ通知 → /cr-fix を手動実行
```

## 前提条件

- **gh CLI** — 認証済みの状態（`gh auth status` で確認可能）
- **Claude Code** — インストール済み
- **jq** — Bash版のみ必要（`jq --version` で確認可能）
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt install jq`
  - WSL: `apt install jq`

## インストール

### macOS / Linux / Git Bash / WSL

```bash
cd cr-watch
./install.sh
```

### PowerShell (Windows)

```powershell
cd cr-watch
.\install.ps1
```

インストール後、Claude Codeを再起動して設定を反映させてください。

## 仕組み

### フロー

```
gh pr create
    ↓
cr-watch-launcher.sh（PostToolUse hookで自動発火）
    ↓
cr-watch.sh（バックグラウンドで起動）
    ↓
2分ごとにCodeRabbitのレビュー状態をチェック（最大5回 = 10分）
    ↓
レビュー完了を検知（APPROVED or CHANGES_REQUESTED）
    ↓
デスクトップ通知（macOS: osascript / Windows: WScript.Shell / Linux: notify-send）
```

### コンポーネント

- **cr-watch.sh / cr-watch.ps1** — CodeRabbitのレビュー状態をポーリングし、完了時にデスクトップ通知
- **cr-watch-launcher.sh / cr-watch-launcher.ps1** — `gh pr create` 実行を検知してwatcherをバックグラウンド起動
- **install.sh / install.ps1** — hookファイルを `~/.claude/hooks/` にコピーし、settings.jsonにhook登録
- **uninstall.sh / uninstall.ps1** — hookファイル削除とsettings.jsonからのhook解除

## 設定

ポーリング動作は環境変数で調整可能です：

| 環境変数 | デフォルト | 説明 |
|---------|-----------|------|
| `CR_WATCH_INTERVAL` | 120（秒） | ポーリング間隔 |
| `CR_WATCH_MAX_CHECKS` | 5（回） | 最大チェック回数 |

例：30秒ごと、20回チェック（計10分）

```bash
export CR_WATCH_INTERVAL=30
export CR_WATCH_MAX_CHECKS=20
```

## アンインストール

### macOS / Linux / Git Bash / WSL

```bash
cd cr-watch
./uninstall.sh
```

### PowerShell (Windows)

```powershell
cd cr-watch
.\uninstall.ps1
```

## トラブルシューティング

### ghコマンドが見つからない、または認証されていない

```bash
gh auth status
```

状態確認後、必要に応じて再認証：

```bash
gh auth login
```

### jqコマンドが見つからない（Bash版）

```bash
jq --version
```

バージョン表示がない場合はインストール：

```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt install jq
```

### デスクトップ通知が表示されない

#### macOS

システム環境設定 → 通知 → ターミナル（またはClaude Code）が「通知を許可」に設定されているか確認してください。

#### Windows（PowerShell）

Windows設定 → システム → 通知とアクション → 通知 が有効に設定されているか確認してください。

#### WSL

`powershell.exe` 経由で通知を送ります。以下で確認：

```bash
which powershell.exe
```
