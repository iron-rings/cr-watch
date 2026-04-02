param(
    [Parameter(Mandatory=$true)][string]$PR
)

$MaxChecks = if ($env:CR_WATCH_MAX_CHECKS) { [int]$env:CR_WATCH_MAX_CHECKS } else { 5 }
$Interval = if ($env:CR_WATCH_INTERVAL) { [int]$env:CR_WATCH_INTERVAL } else { 120 }
$PidFile = Join-Path $env:TEMP "cr-watch-$PR.pid"
$MutexName = "cr-watch-$PR"

function Notify {
    param([string]$Title, [string]$Message)
    try {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.Popup($Message, 5, $Title, 64) | Out-Null
    } catch {
        Write-Host "[$Title] $Message"
    }
}

# Duplicate prevention via named mutex
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$createdNew)
if (-not $createdNew) {
    exit 0
}

try {
    $PID | Set-Content $PidFile

    $count = 0
    while ($count -lt $MaxChecks) {
        try {
            $stateJson = gh pr view $PR --json state 2>$null
            $state = ($stateJson | ConvertFrom-Json).state
        } catch {
            $state = "UNKNOWN"
        }

        if ($state -eq "UNKNOWN") {
            Start-Sleep -Seconds $Interval
            continue
        }

        if ($state -ne "OPEN") {
            Notify "cr-watch終了" "PRがクローズされました"
            exit 0
        }

        try {
            $reviewsJson = gh pr view $PR --json reviews 2>$null
            $reviews = ($reviewsJson | ConvertFrom-Json).reviews |
                Where-Object { $_.author.login -eq "coderabbitai" }
            $latest = $reviews | Select-Object -Last 1
            $crStatus = if ($latest) { $latest.state } else { "" }
        } catch {
            $crStatus = ""
        }

        if ($crStatus -match 'APPROVED|CHANGES_REQUESTED') {
            Notify "CodeRabbit完了" "cr-fix を実行してください"
            exit 0
        }

        $count++
        Start-Sleep -Seconds $Interval
    }
} finally {
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
