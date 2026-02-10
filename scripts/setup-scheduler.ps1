# Claude Code Agent Teams - Windows Task Scheduler 자동 동기화 설정
# 사용법: powershell -ExecutionPolicy Bypass -File setup-scheduler.ps1 -RepoPath "C:\path\to\repo"
#
# 이 스크립트의 역할:
# - Windows에서 주기적으로 git pull + add + commit + push를 실행합니다
# - WSL과 Windows 간 파일을 자동으로 동기화하여, 양쪽에서 작업한 내용이 유실되지 않도록 합니다
# - 기본 간격: 매 :00, :30 (30분마다)

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
`$branch = (git branch --show-current 2>&1).Trim()
if (-not `$branch) { `$branch = "main" }
`$pullResult = git pull origin `$branch --rebase 2>&1
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
    `$pushResult = git push origin `$branch 2>&1
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
    -Once -At (Get-Date).Date `
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
