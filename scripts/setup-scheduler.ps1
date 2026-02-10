# Claude Code Agent Teams - Windows Task Scheduler 설정
# 사용법: powershell -ExecutionPolicy Bypass -File setup-scheduler.ps1 -RepoPath "C:\path\to\repo"
#
# 매 :00, :30에 git pull + add + commit + push 실행

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoPath,

    [int]$IntervalMinutes = 30,

    [string]$TaskName = "AI-Vault-Auto-Push"
)

Write-Host "========================================="
Write-Host " Claude Code Agent Teams - Scheduler Setup"
Write-Host "========================================="
Write-Host ""
Write-Host "Repository: $RepoPath"
Write-Host "Interval: Every $IntervalMinutes minutes"
Write-Host ""

# 기존 작업 확인 및 삭제
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "기존 작업 '$TaskName'을 삭제합니다..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# auto-push 스크립트 생성
$scriptPath = Join-Path $RepoPath "auto-push.ps1"
$scriptContent = @"
# Auto-sync script for Claude Code Agent Teams
# Runs every $IntervalMinutes minutes via Task Scheduler

`$repoPath = "$RepoPath"
`$logFile = Join-Path `$repoPath "auto-push.log"

function Write-Log(`$msg) {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path `$logFile -Value "[`$timestamp] `$msg"
}

Set-Location `$repoPath

# Pull first (get WSL changes)
`$pullResult = git pull origin master --rebase 2>&1
if (`$LASTEXITCODE -eq 0) {
    Write-Log "Pull successful"
} else {
    Write-Log "Pull failed: `$pullResult"
}

# Check for local changes
`$status = git status --porcelain
if (`$status) {
    git add -A
    `$commitMsg = "Auto-sync: `$(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git commit -m `$commitMsg 2>&1
    `$pushResult = git push origin master 2>&1
    if (`$LASTEXITCODE -eq 0) {
        Write-Log "Push successful: `$commitMsg"
    } else {
        Write-Log "Push failed: `$pushResult"
    }
} else {
    Write-Log "No changes to push"
}
"@

Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
Write-Host "auto-push.ps1 생성 완료: $scriptPath"

# Task Scheduler 등록
$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger `
    -Once -At '2026-01-01T00:00:00' `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Claude Code Agent Teams auto git sync (every ${IntervalMinutes}min)"

Write-Host ""
Write-Host "========================================="
Write-Host " Task Scheduler 등록 완료!"
Write-Host ""
Write-Host " 작업 이름: $TaskName"
Write-Host " 실행 간격: ${IntervalMinutes}분 (정각 기준)"
Write-Host " 스크립트: $scriptPath"
Write-Host "========================================="
