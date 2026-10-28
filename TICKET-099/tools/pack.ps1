<#
  제출 파일 만들기 — _submit\<학번>_<이름>_중간과제\ 폴더와 같은 이름의 zip을 만듭니다.

    보고서.pdf / 보고서.md
    증거\                    (png + logs)
    측정결과_<학번>.csv       (LoadTester가 만든 그대로)
    소스\                    (sln, Shared, OutsourcedServer, TestClient, LoadTester — bin·obj·.vs 제외)
    git.txt                  (저장소 주소 + git log --oneline --graph --all --decorate + 커밋 시각)

  사용 예)  tools\pack
#>
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $PSScriptRoot

$cfg = Get-Content -LiteralPath (Join-Path $root 'Shared\StudentConfig.cs') -Raw -Encoding UTF8
$id = ''; $nm = ''
if ($cfg -match 'STUDENT_ID\s*=\s*(\d+)\s*;') { $id = $Matches[1] }
if ($cfg -match 'STUDENT_NAME\s*=\s*"([^"]*)"') { $nm = $Matches[1] }
if (-not $id -or $id -eq '0' -or -not $nm -or $nm -eq '미입력') {
    Write-Host 'StudentConfig.cs 의 학번·이름을 먼저 확인하세요.' -ForegroundColor Red
    exit 1
}

$name  = "${id}_${nm}_중간과제"
$out   = Join-Path $root '_submit'
$stage = Join-Path $out $name
$zip   = Join-Path $out "$name.zip"
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$missing = @()

# 보고서
foreach ($r in @('보고서.pdf', '보고서.md')) {
    $p = Join-Path $root $r
    if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $stage } else { $missing += $r }
}

# 증거
$ev = Join-Path $root '증거'
if (Test-Path -LiteralPath $ev) {
    Copy-Item -LiteralPath $ev -Destination (Join-Path $stage '증거') -Recurse
    Get-ChildItem -LiteralPath (Join-Path $stage '증거') -Filter 'README.md' -File | Remove-Item -Force
} else { $missing += '증거\' }

# CSV (LoadTester가 만든 그대로 복사)
$csv = Get-ChildItem -LiteralPath $root -Filter "측정결과_$id.csv" -File -ErrorAction SilentlyContinue
if ($csv) { Copy-Item -LiteralPath $csv.FullName -Destination $stage } else { $missing += "측정결과_$id.csv" }

# 소스
$srcDir = Join-Path $stage '소스'
New-Item -ItemType Directory -Force -Path $srcDir | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'TICKET-099.sln') -Destination $srcDir
foreach ($d in @('Shared', 'OutsourcedServer', 'TestClient', 'LoadTester')) {
    Copy-Item -LiteralPath (Join-Path $root $d) -Destination (Join-Path $srcDir $d) -Recurse
}
Get-ChildItem -LiteralPath $srcDir -Recurse -Directory -Force |
    Where-Object { $_.Name -in @('bin', 'obj', '.vs') } |
    Sort-Object { $_.FullName.Length } -Descending |
    ForEach-Object { if (Test-Path -LiteralPath $_.FullName) { Remove-Item -LiteralPath $_.FullName -Recurse -Force } }
Get-ChildItem -LiteralPath $srcDir -Recurse -File -Filter '*.user' | Remove-Item -Force

# git.txt (git 이 stderr 에 경고를 써도 멈추지 않게 이 구간만 Continue)
Push-Location $root
$eapOld = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
try {
    $url = (& git remote get-url origin 2>$null)
    if (-not $url) { $url = '(원격 저장소 주소 없음 — git remote add origin <주소> 후 다시 실행)'; $missing += '저장소 주소' }
    $branch = (& git rev-parse --abbrev-ref HEAD 2>$null)
    $log = (& git --no-pager log --oneline --graph --all --decorate 2>$null) -join "`r`n"
    $base = (& git merge-base HEAD origin/main 2>$null)
    $note = ''; $dated = ''
    if ($base) {
        $short = (& git rev-parse --short $base 2>$null)
        $n1 = (& git rev-list --count "$base..HEAD" 2>$null)
        $exp = @(& git branch --list 'exp/*' --format='%(refname:short)' 2>$null | Where-Object { $_ })
        $n2 = 0; foreach ($e in $exp) { $n2 += [int](& git rev-list --count "HEAD..$e" 2>$null) }
        $note = "이번 과제 커밋 : $branch ${n1}개" + $(if ($exp.Count) { " + " + ($exp -join ', ') + " ${n2}개" } else { '' }) + "`r`n" +
                "$short 와 그 아래 커밋은 2~5주차 수업 때 만든 것 (이번 과제 이전)`r`n"
        # 푸시 상태 (원격 브랜치와 같은 커밋인지)
        foreach ($bname in @($branch) + $exp) {
            $loc = (& git rev-parse --short $bname 2>$null)
            $rem = (& git rev-parse --short "origin/$bname" 2>$null)
            if (-not $rem) { $rem = '(원격에 없음)' }
            $note += "푸시 상태 : $bname 로컬 $loc / origin $rem" + $(if ($loc -eq $rem) { ' (같음)' } else { ' (다름 — git push 필요)' }) + "`r`n"
        }
        # 커밋 시각 목록 (이번 과제 커밋만, 오래된 것부터)
        $dated = "`r`n[커밋 시각 — $branch]`r`n" + ((& git --no-pager log --reverse --format='%h  %ad  %s' --date=format:'%Y-%m-%d %H:%M:%S' "$base..HEAD" 2>$null) -join "`r`n") + "`r`n"
        foreach ($e in $exp) {
            $dated += "`r`n[커밋 시각 — $e]`r`n" + ((& git --no-pager log --reverse --format='%h  %ad  %s' --date=format:'%Y-%m-%d %H:%M:%S' "HEAD..$e" 2>$null) -join "`r`n") + "`r`n"
        }
    }
    $body = "저장소 : $url`r`n브랜치 : $branch`r`n$note`r`n[git log --oneline --graph --all --decorate]`r`n$log`r`n$dated"
    [System.IO.File]::WriteAllText((Join-Path $stage 'git.txt'), $body, (New-Object System.Text.UTF8Encoding($true)))
} finally { Pop-Location; $ErrorActionPreference = $eapOld }

# zip (한글 파일 이름이 깨지지 않게 UTF-8로, 폴더 구분자는 / 로 — 어느 OS에서 풀어도 폴더가 살아 있게)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fs = [System.IO.File]::Open($zip, [System.IO.FileMode]::Create)
$za = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false, [System.Text.Encoding]::UTF8)
try {
    $stageFull = (Resolve-Path -LiteralPath $stage).Path
    foreach ($f in Get-ChildItem -LiteralPath $stageFull -Recurse -File) {
        $rel = $f.FullName.Substring($stageFull.Length).TrimStart('\', '/') -replace '\\', '/'
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $f.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally {
    $za.Dispose()
    $fs.Dispose()
}

$pngs = @(Get-ChildItem -LiteralPath $stage -Recurse -Filter '*.png' -File).Count
Write-Host ''
Write-Host "만든 파일 : $zip" -ForegroundColor Green
Write-Host "  캡처 $pngs 장 · $((Get-Item -LiteralPath $zip).Length / 1MB -as [int]) MB"
if ($missing.Count -gt 0) {
    Write-Host ("빠진 것 : " + ($missing -join ', ')) -ForegroundColor Yellow
}
Write-Host '올린 뒤 직접 내려받아 압축을 풀고 보고서가 열리는지 꼭 확인하세요.' -ForegroundColor Cyan
