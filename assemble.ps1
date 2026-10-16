# assemble.ps1 — dựng DubPlay.zip để chia sẻ (chạy trên máy có cài mpv).
# Nguồn mpv: cài qua winget (shinchiro.mpv) hoặc chỉ định -MpvDir.
# Đóng gói qua thư mục tạm (tránh bị lock nếu bundle/ cũ đang mở bởi tiến trình khác).
# Kết quả: dubplay/DubPlay.zip
param(
  [string]$MpvDir = "C:\Program Files\MPV Player"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path (Join-Path $MpvDir 'mpv.exe'))) {
  Write-Host "[LOI] Khong thay mpv.exe trong '$MpvDir'. Cai:  winget install shinchiro.mpv" -ForegroundColor Red
  exit 1
}

$stage = Join-Path $env:TEMP ('DubPlay-stage-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $stage | Out-Null

# mpv nguyên bản + dll kèm theo (không sửa — chỉ đóng gói lại, GPL cho phép)
Copy-Item (Join-Path $MpvDir '*') $stage -Exclude 'uninstall.exe'
# Dọn thư mục rác của gói winget (không cần cho chạy portable; updater.bat
# phải đi vì nó có thể tự nâng cấp mpv và phá tính ổn định của bundle)
foreach ($junk in @('mpv', 'doc', 'installer', 'uninstall.exe', 'unins000.dat', 'unins000.exe', 'updater.bat')) {
  $p = Join-Path $stage $junk
  if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue }
}
# Phần custom của DubPlay
Copy-Item (Join-Path $root 'portable_config') $stage -Recurse
Copy-Item (Join-Path $root 'DubPlay.bat') $stage
# Nhãn thương hiệu: mpv.exe -> DubPlay.exe (mpv không quan tâm tên file exe).
# Bỏ mpv.com (wrapper console — người dùng cuối không cần).
Rename-Item (Join-Path $stage 'mpv.exe') 'DubPlay.exe'
Remove-Item (Join-Path $stage 'mpv.com') -ErrorAction SilentlyContinue

$zip = Join-Path $root 'DubPlay.zip'
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
Write-Host "XONG: $zip ($([math]::Round((Get-Item $zip).Length / 1MB, 1)) MB)" -ForegroundColor Green
