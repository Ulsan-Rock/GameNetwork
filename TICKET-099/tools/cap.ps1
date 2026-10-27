<#
  화면 캡처 — 몇 초 뒤 전체 화면을 증거\<이름>_<월일_시분초>.png 로 저장합니다.
  작업표시줄 시계까지 같이 찍혀서 재현 시각 증거가 됩니다.

  사용 예)
    tools\cap A1_before_split            3초 뒤 모든 모니터 캡처
    tools\cap A1_before_split -Delay 5   5초 뒤
    tools\cap B0_info_pcinfo -Primary    주 모니터만

  이름 규칙 : <ID>_<before|after|proof|info>_<요약>
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [int]$Delay = 3,
    [switch]$Primary
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 배율(125%, 150%)이 걸린 화면에서도 잘리지 않도록 실제 픽셀 기준으로 맞춥니다
if (-not ('CapDpi' -as [type])) {
    Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class CapDpi {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
}
[void][CapDpi]::SetProcessDPIAware()

$root = Split-Path -Parent $PSScriptRoot
$dir  = Join-Path $root '증거'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$safe = ($Name -replace '[\\/:*?"<>|\s]+', '_')
$file = Join-Path $dir ('{0}_{1}.png' -f $safe, (Get-Date -Format 'MMdd_HHmmss'))

Write-Host "찍을 창을 앞으로 가져오세요 ($Delay 초)" -ForegroundColor Yellow
for ($i = $Delay; $i -gt 0; $i--) { Write-Host "  $i ..."; Start-Sleep -Seconds 1 }

if ($Primary) { $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds }
else          { $b = [System.Windows.Forms.SystemInformation]::VirtualScreen }

$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g   = [System.Drawing.Graphics]::FromImage($bmp)
try {
    $g.CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size)
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $g.Dispose()
    $bmp.Dispose()
}

Write-Host "저장 : $file" -ForegroundColor Green
