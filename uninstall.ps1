$hooksDir = Join-Path $HOME ".claude" "hooks"
$settingsPath = Join-Path $HOME ".claude" "settings.json"

Remove-Item "$hooksDir\cr-watch.sh", "$hooksDir\cr-watch.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$hooksDir\cr-watch-launcher.sh", "$hooksDir\cr-watch-launcher.ps1" -Force -ErrorAction SilentlyContinue

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $settings.hooks.PostToolUse = @($settings.hooks.PostToolUse | Where-Object {
        -not ($_.hooks | Where-Object { $_.command -like "*cr-watch-launcher*" })
    })
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
}

Write-Host "✅ cr-watch uninstalled."
