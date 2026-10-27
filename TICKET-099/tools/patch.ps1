<#
  단계별 수정 파일 적용 — patches\<단계>\ 의 파일을 같은 위치에 덮어씁니다.
  원래 파일의 줄바꿈(CRLF/LF)과 BOM을 그대로 맞춰서, git에는 바뀐 줄만 남습니다.

  사용 예)  tools\patch A7
  순서     A7 → A3 → A1 → A2 → A4 → A5 → A6 → A8      (실험 브랜치에서만 : exp3)
  각 단계 파일은 앞 단계까지 반영된 상태라서 반드시 이 순서대로 적용하세요.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Step
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root "patches\$Step"

if (-not (Test-Path -LiteralPath $src)) {
    $have = (Get-ChildItem -LiteralPath (Join-Path $root 'patches') -Directory | ForEach-Object { $_.Name }) -join ', '
    Write-Host "patches\$Step 이 없습니다. 있는 단계 : $have" -ForegroundColor Red
    exit 1
}

$srcFull = (Resolve-Path -LiteralPath $src).Path
foreach ($f in Get-ChildItem -LiteralPath $srcFull -Recurse -File) {
    $rel = $f.FullName.Substring($srcFull.Length).TrimStart('\', '/')
    if ($rel -like 'LoadTester*') { throw 'LoadTester 는 고치면 안 됩니다.' }

    $dst  = Join-Path $root $rel
    $crlf = $false
    $bom  = $false
    if (Test-Path -LiteralPath $dst) {
        $bytes = [System.IO.File]::ReadAllBytes($dst)
        $bom   = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        $crlf  = [System.Text.Encoding]::UTF8.GetString($bytes).Contains("`r`n")
    } else {
        Write-Host "주의 : $rel 이 원래 없던 파일입니다. 폴더 위치를 확인하세요." -ForegroundColor Yellow
    }

    $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8).Replace("`r`n", "`n")
    if ($crlf) { $text = $text.Replace("`n", "`r`n") }
    [System.IO.File]::WriteAllText($dst, $text, (New-Object System.Text.UTF8Encoding($bom)))
    Write-Host "적용 : $rel" -ForegroundColor Green
}

Push-Location $root
try { & git --no-pager diff --stat } catch { }
Pop-Location

Write-Host ''
Write-Host "다음 : 떠 있는 창을 모두 닫고 tools\start  →  같은 시나리오  →  tools\cap ${Step}_after_...  →  git commit" -ForegroundColor Cyan
