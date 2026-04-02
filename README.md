# cr-watch

Claude CodeでPR作成後、CodeRabbitのレビュー完了を自動検知してデスクトップ通知を送るツールです。

## これは何？

普段の開発フローで起きる問題：

1. Claude Codeで作業 → PRを作成
2. CodeRabbitが自動レビュー開始（数分かかる）
3. **いつ終わったかわからない** ← ここが問題
4. 手動でGitHubを見に行く or 放置して忘れる

cr-watchはこの問題を解決します：

```text
PR作成 → 自動でポーリング開始 → CodeRabbit完了 → デスクトップ通知！ → /cr-fix で対応
```

**インストール後は何もしなくてOK。** PRを作るだけで自動的に監視が始まります。

## クイックスタート

```bash
# 1. クローン
git clone https://github.com/iron-rings/cr-watch.git

# 2. インストール
cd cr-watch && ./install.sh

# 3. 動作確認（macOSの場合）
osascript -e 'display notification "cr-watchテスト" with title "cr-watch" sound name "Glass"'
# → 右上に通知が出ればOK
```

Windows（PowerShell）の場合：
```powershell
git clone https://github.com/iron-rings/cr-watch.git
cd cr-watch; .\install.ps1
```

## 前提条件

| 必要なもの | 確認方法 | 備考 |
|-----------|---------|------|
| Claude Code | — | インストール済みであること |
| gh CLI（認証済み） | `gh auth status` | 未認証なら `gh auth login` |
| jq | `jq --version` | Bash版のみ必要。PowerShell版は不要 |
| CodeRabbit | GitHubでPRにレビューが来るか | リポジトリにCodeRabbitが接続済みであること |

## 仕組み

### 全体フロー

```text
あなたがClaude Codeで作業
    ↓
gh pr create（Claude Codeが実行）
    ↓
cr-watch-launcher.sh が自動発火（PostToolUse hook）
  └→ PRのURLからPR番号を抽出
    ↓
cr-watch.sh がバックグラウンドで起動
  └→ 2分おきに gh pr view でCodeRabbitのレビュー状態をチェック
  └→ 最大5回（10分間）
    ↓
CodeRabbitのレビュー完了を検知（APPROVED or CHANGES_REQUESTED）
    ↓
デスクトップ通知「CodeRabbit完了 — cr-fix を実行してください」
    ↓
あなたがClaude Codeで /cr-fix を実行
  └→ CodeRabbitの指摘を自動取得・分類・修正
```

### `/cr-fix` とは？

通知が来たらClaude Codeで実行するコマンドです：

```text
/cr-fix <PR番号>
```

CodeRabbitの未解決コメントを取得し、自動で修正コードを適用します。
（Claude Codeの `cr-fix` スキルが必要です）

### ファイル構成

```text
~/.claude/hooks/          ← インストール先
├── cr-watch.sh           ← 監視スクリプト（Bash）
├── cr-watch.ps1          ← 監視スクリプト（PowerShell）
├── cr-watch-launcher.sh  ← hook起動（Bash）
└── cr-watch-launcher.ps1 ← hook起動（PowerShell）

~/.claude/settings.json   ← PostToolUse hookが自動登録される
```

### 対応環境

| 環境 | 通知方法 |
|------|---------|
| macOS | osascript（システム通知） |
| Windows（PowerShell） | WScript.Shell Popup |
| Windows（Git Bash） | powershell.exe 経由 |
| WSL | powershell.exe 経由 |
| Linux（デスクトップ） | notify-send |
| Linux（サーバー/SSH） | 通知なし（サイレント終了） |

## 設定

環境変数でポーリング動作を調整できます：

| 環境変数 | デフォルト | 説明 |
|---------|-----------|------|
| `CR_WATCH_INTERVAL` | 120（秒） | ポーリング間隔 |
| `CR_WATCH_MAX_CHECKS` | 5（回） | 最大チェック回数 |

例：30秒ごと、20回チェック（計10分）

```bash
export CR_WATCH_INTERVAL=30
export CR_WATCH_MAX_CHECKS=20
```

## 動作確認

### 通知テスト

```bash
# macOS
osascript -e 'display notification "テスト" with title "cr-watch" sound name "Glass"'

# Windows (PowerShell)
[void](New-Object -ComObject WScript.Shell).Popup("テスト", 5, "cr-watch", 64)
```

### hookテスト（PRを作らずに確認）

```bash
# モック入力でlauncherを実行
echo '{"tool_input":{"command":"gh pr create --title test"},"tool_result":"https://github.com/owner/repo/pull/999"}' | ~/.claude/hooks/cr-watch-launcher.sh

# プロセスが起動したか確認
pgrep -af "cr-watch.*999"

# テストプロセスを停止
kill $(cat /tmp/cr-watch-999.pid) 2>/dev/null; rm -f /tmp/cr-watch-999.pid
```

## アンインストール

```bash
# macOS / Linux / Git Bash / WSL
cd cr-watch && ./uninstall.sh

# PowerShell (Windows)
cd cr-watch; .\uninstall.ps1
```

hookファイルの削除と settings.json からのhook解除を行います。

## トラブルシューティング

### 通知が来ない

1. **CodeRabbitが接続されているか確認**: GitHubでPRにCodeRabbitのレビューが来ているか
2. **hookが登録されているか確認**: `cat ~/.claude/settings.json | grep cr-watch`
3. **hookファイルが存在するか確認**: `ls ~/.claude/hooks/cr-watch*`
4. **OS通知設定**: macOSはシステム設定→通知、Windowsは通知センターを確認

### ghの認証エラー

```bash
gh auth status   # 状態確認
gh auth login    # 再認証
```

### jqが見つからない

```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt install jq
```
