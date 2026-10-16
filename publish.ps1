# publish.ps1 - build + commit + push + phat hanh release, moi thu trong 1 lenh.
# Chay:  powershell -ExecutionPolicy Bypass -File publish.ps1 [-Version 1.1.0]
# LUU Y: file nay PHAI la ASCII thuan (khong dau) - PS 5.1 doc UTF-8 thieu
# BOM nhu ANSI, ky tu dac biet nhu em dash se bien thanh dau nhay va lam vo script.
param([string]$Version = "1.1.0")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# ---- 1. Build zip Windows (mpv + config) ----
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'assemble.ps1')
$winZip = "DubPlay-Windows-v$Version.zip"
Rename-Item (Join-Path $root 'DubPlay.zip') $winZip

# ---- 2. Build zip macOS app (python: tai mpv.app chinh thuc, rebrand DubPlay, quyen +x) ----
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if ($py) { $pyExe = $py.Source }
else { $pyExe = 'N:\59\Dubbing-pro\.claude\skills\.venv\Scripts\python.exe' }
$macArmZip = "DubPlay-macOS-AppleSilicon-v$Version.zip"
$macIntelZip = "DubPlay-macOS-Intel-v$Version.zip"
& $pyExe (Join-Path $root 'assemble-mac-app.py') arm64 (Join-Path $root $macArmZip)
& $pyExe (Join-Path $root 'assemble-mac-app.py') intel (Join-Path $root $macIntelZip)

# ---- 3. Commit + push ----
if (git status --porcelain) {
  git add -A
  git commit -m "feat(mac): DubPlay.app bundle - drag-to-Applications install, no Terminal/brew"
}
git push origin main

# ---- 4. Phat hanh release ----
gh release create "v$Version" $winZip $macArmZip $macIntelZip --title "DubPlay v$Version" --notes-file (Join-Path $root "release-notes-v$Version.md")

# ---- 5. Don dep ----
Remove-Item $winZip, $macArmZip, $macIntelZip -ErrorAction SilentlyContinue
git fetch --tags
Write-Host "XONG: release v$Version da len GitHub (Win + Mac AppleSilicon + Mac Intel)"
