<#
  TICKET-099 실행 도우미 — 서버 / LoadTester / TestClient 를 각각 새 창으로 띄웁니다.
  창 제목에 학번과 포트가 찍혀서, 전체 화면 캡처 한 장에 증거가 다 들어갑니다.
  서버 콘솔 내용은 증거\logs\server_<시각>.log 에도 같이 저장됩니다.

  사용 예)  (sln 이 있는 폴더에서)
    tools\start                     서버 + LoadTester
    tools\start -Client 2           서버 + LoadTester + TestClient 2개
    tools\start -Only Server        서버만
    tools\start -Only Load          LoadTester 만 (서버가 이미 떠 있을 때)
    tools\start -Only Client -Client 2
    tools\start -NoBuild            빌드 생략 (코드 안 바꿨을 때)
    tools\start -NoLog              서버 로그 파일 저장 안 함
#>
param(
    [ValidateSet('All', 'Server', 'Load', 'Client')]
    [string]$Only = 'All',
    [int]$Client = 0,
    [switch]$NoBuild,
    [switch]$NoLog
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sln  = Join-Path $root 'TICKET-099.sln'

if (-not (Test-Path -LiteralPath $sln)) {
    Write-Host "TICKET-099.sln 을 못 찾았습니다. tools 폴더를 sln 옆에 두세요. (지금 위치: $root)" -ForegroundColor Red
    exit 1
}

# ── 학번 → 포트 (StudentConfig.cs 와 같은 계산) ──
$cfgText = Get-Content -LiteralPath (Join-Path $root 'Shared\StudentConfig.cs') -Raw -Encoding UTF8
$id = 0
if ($cfgText -match 'STUDENT_ID\s*=\s*(\d+)\s*;') { $id = [long]$Matches[1] }
if ($id -le 0) {
    Write-Host 'Shared\StudentConfig.cs 의 STUDENT_ID 에 학번부터 넣으세요.' -ForegroundColor Red
    exit 1
}
$tcp = 10000 + ($id % 1999) * 2
$udp = $tcp + 1
Write-Host "학번 $id  ->  TCP $tcp / UDP $udp" -ForegroundColor Cyan

# ── 빌드 ──
if (-not $NoBuild) {
    Write-Host '빌드 중 (Release) ...'
    & dotnet build $sln -c Release --nologo -v q
    if ($LASTEXITCODE -ne 0) {
        Write-Host '빌드 실패. 떠 있는 서버/클라이언트 창을 모두 닫고(exe 잠김) 다시 해보세요.' -ForegroundColor Red
        exit 1
    }
}

function Get-Exe([string]$proj) {
    $p = Join-Path $root "$proj\bin\Release\net8.0\$proj.exe"
    if (-not (Test-Path -LiteralPath $p)) { throw "$p 가 없습니다. -NoBuild 없이 다시 실행하세요." }
    return $p
}

$logDir = Join-Path $root '증거\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$stamp = Get-Date -Format 'MMdd_HHmmss'

# 새 PowerShell 창을 열어 명령을 실행합니다. (한글 경로·따옴표 문제를 피하려고 EncodedCommand 사용)
function Open-Console([string]$title, [string]$body) {
    $script = @(
        ('$Host.UI.RawUI.WindowTitle = ''{0}''' -f $title),
        '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8',
        ('Set-Location -LiteralPath ''{0}''' -f $root),
        $body
    ) -join "`r`n"
    $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script))
    Start-Process powershell -ArgumentList @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $enc) | Out-Null
}

$tag = "학번 $id  TCP $tcp / UDP $udp"

if ($Only -eq 'All' -or $Only -eq 'Server') {
    $exe = Get-Exe 'OutsourcedServer'
    if ($NoLog) {
        $body = '& ''{0}''' -f $exe
    } else {
        $log  = Join-Path $logDir "server_$stamp.log"
        # 화면에 그대로 보여주면서 한 줄씩 로그 파일에도 씁니다 (예외 스택도 같이)
        $body = '& ''{0}'' 2>&1 | ForEach-Object {{ $l = "$_"; Write-Host $l; Add-Content -LiteralPath ''{1}'' -Value $l -Encoding UTF8 }}' -f $exe, $log
        Write-Host "서버 로그 : $log"
    }
    Open-Console "SERVER  $tag" $body
    Start-Sleep -Milliseconds 1500   # 서버가 포트를 열 시간
}

if ($Only -eq 'All' -or $Only -eq 'Load') {
    $exe = Get-Exe 'LoadTester'
    # 작업 폴더가 sln 폴더라서 측정결과_<학번>.csv 가 여기에 생깁니다
    Open-Console "LOADTESTER  $tag" ('& ''{0}''' -f $exe)
}

if ($Client -gt 0) {
    $exe = Get-Exe 'TestClient'
    for ($i = 1; $i -le $Client; $i++) {
        Open-Console "TESTCLIENT $i  $tag" ('& ''{0}''' -f $exe)
        Start-Sleep -Milliseconds 300
    }
}

Write-Host '창을 띄웠습니다. Win+방향키로 나란히 배치한 뒤 tools\cap <이름> 으로 캡처하세요.' -ForegroundColor Green
