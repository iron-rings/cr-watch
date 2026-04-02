$ErrorActionPreference = "Stop"

$hooksDir = Join-Path $HOME ".claude" "hooks"
$settingsPath = Join-Path $HOME ".claude" "settings.json"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Check dependencies
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "gh CLI is required. Install from https://cli.github.com/"
    exit 1
}

# 2. Create hooks directory
New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null

# 3. Copy hook files
Copy-Item "$scriptDir\hooks\*" -Destination $hooksDir -Force

# 4. Merge settings.json (depth 10 to preserve nested structure)
if (Test-Path $settingsPath) {
    Copy-Item $settingsPath "$settingsPath.bak"
}
$hookEntry = @{
    matcher = "Bash"
    hooks = @(@{type="command"; command="~/.claude/hooks/cr-watch-launcher.sh"; statusMessage=""})
}

if (-not (Test-Path $settingsPath)) {
    @{hooks=@{PostToolUse=@($hookEntry)}} | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
} else {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $existing = $settings.hooks.PostToolUse | Where-Object {
        $_.hooks | Where-Object { $_.command -like "*cr-watch-launcher*" }
    }
    if ($existing) {
        Write-Host "cr-watch hook already registered. Skipping settings.json."
    } else {
        if (-not $settings.hooks.PostToolUse) {
            $settings.hooks | Add-Member -NotePropertyName PostToolUse -NotePropertyValue @($hookEntry)
        } else {
            $settings.hooks.PostToolUse = @($settings.hooks.PostToolUse) + $hookEntry
        }
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    }
}

Write-Host "✅ cr-watch installed. CodeRabbit review notifications are now active."
