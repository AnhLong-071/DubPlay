# install-windows.ps1 — cài DubPlay lên máy Windows (không cần quyền admin).
# Việc nó làm:
#   1. Giải nén DubPlay.zip (hoặc copy từ -Source) vào %LOCALAPPDATA%\DubPlay
#   2. Đăng ký "Open with": right-click video -> Open with -> DubPlay
#   3. Tạo shortcut "DubPlay" trong Start Menu (mở hộp chọn video)
# Cách chạy:  powershell -ExecutionPolicy Bypass -File install-windows.ps1
param(
  [string]$Source = ""  # thư mục bundle đã giải nén; bỏ trống = dùng DubPlay.zip cạnh script
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:LOCALAPPDATA 'DubPlay'

# ---- 1. Đặt file vào chỗ (ghi đè tại chỗ — KHÔNG xoá trước, tránh rơi vào
# trạng thái nửa vời nếu DubPlay.exe đang chạy bị khoá) ----
if ($Source -ne '' -and (Test-Path (Join-Path $Source 'DubPlay.exe'))) {
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Copy-Item (Join-Path $Source '*') $dest -Force
} else {
  $zip = Join-Path $root 'DubPlay.zip'
  if (-not (Test-Path $zip)) {
    Write-Host "[LỖI] Không thấy DubPlay.zip. Chạy assemble.ps1 trước hoặc truyền -Source <thư mục bundle>." -ForegroundColor Red
    exit 1
  }
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  # -Force ghi đè file chưa bị khoá; exe đang chạy sẽ được giữ nguyên (cũ),
  # người dùng đóng player rồi chạy lại installer là lên đời.
  Expand-Archive -Path $zip -DestinationPath $dest -Force -ErrorAction SilentlyContinue
}

$exe = Join-Path $dest 'DubPlay.exe'
if (-not (Test-Path $exe)) {
  Write-Host "[LỖI] Sau khi cài không thấy DubPlay.exe — bundle không đúng cấu trúc." -ForegroundColor Red
  exit 1
}

# ---- 2. Đăng ký "Open with" (HKCU — không cần admin) ----
$classes = 'HKCU:\Software\Classes\Applications\DubPlay.exe'
# FriendlyAppName: Windows mặc định lấy tên từ metadata nhúng trong exe (mpv)
# — phải ghi đè để danh sách Open with hiển thị "DubPlay".
New-Item -Path $classes -Force | Out-Null
Set-ItemProperty -Path $classes -Name 'FriendlyAppName' -Value 'DubPlay'
New-Item -Path "$classes\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$classes\shell\open\command" -Name '(Default)' -Value "`"$exe`" `"%1`""
New-Item -Path "$classes\SupportedTypes" -Force | Out-Null
foreach ($ext in @('.mp4', '.mkv', '.avi', '.webm', '.mov', '.wmv', '.flv', '.m4v', '.ts')) {
  New-ItemProperty -Path "$classes\SupportedTypes" -Name $ext -Value '' -PropertyType String -Force | Out-Null
}

# ---- 3. Shortcut Start Menu ----
$sm = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DubPlay.lnk'
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($sm)
$sc.TargetPath = Join-Path $dest 'DubPlay.bat'
$sc.WorkingDirectory = $dest
$sc.Description = 'DubPlay — player video lồng tiếng'
$sc.Save()

Write-Host ""
Write-Host "CÀI XONG ✓  ($dest)" -ForegroundColor Green
Write-Host "Cách dùng:"
Write-Host "  · Right-click video → Open with → Choose another app → DubPlay (tick 'Always' nếu muốn mặc định)"
Write-Host "  · Hoặc kéo video thả vào DubPlay.bat / phím tắt Start Menu 'DubPlay'"
Write-Host "  · Đặt dub_audio*.wav + .srt cạnh video là tự nhận; trong player: a/s/o = chọn file"
