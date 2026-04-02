try {
    $inputText = [Console]::In.ReadToEnd()
    $data = $inputText | ConvertFrom-Json
} catch {
    exit 0
}

$command = $data.tool_input.command
if ($command -notmatch '(^|\s)gh\s+pr\s+create(\s|$)') { exit 0 }

$result = $data.tool_result
if ($result -match '/pull/(\d+)') {
    $pr = $Matches[1]
    Start-Process -NoNewWindow -FilePath "pwsh" -ArgumentList "-File", "$HOME\.claude\hooks\cr-watch.ps1", $pr
}
