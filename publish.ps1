# publish.ps1 — build + commit + push + phat hanh release, moi thu trong 1 lenh.
# Chay:  powershell -ExecutionPolicy Bypass -File publish.ps1 [-Version 1.1.0]
param([string]$Version = "1.1.0")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# ---- 1. Build zip Windows (mpv + config) ----
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'assemble.ps1')
$winZip = "DubPlay-Windows-v$Version.zip"
Rename-Item (Join-Path $root 'DubPlay.zip') $winZip

# ---- 2. Build zip macOS (python dat quyen +x cho .command) ----
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if ($py) { $pyExe = $py.Source }
else { $pyExe = 'N:\59\Dubbing-pro\.claude\skills\.venv\Scripts\python.exe' }
$macZip = "DubPlay-macOS-v$Version.zip"
& $pyExe (Join-Path $root 'assemble-mac.py') (Join-Path $root $macZip)

# ---- 3. Commit + push ----
if (git status --porcelain) {
  git add -A
  git commit -m "feat(install): double-click installers for Windows (.bat) and macOS (.command)"
}
git push origin main

# ---- 4. Phat hanh release ----
gh release create "v$Version" $winZip $macZip --title "DubPlay v$Version" `
  --notes-file (Join-Path $root "release-notes-v$Version.md")

# ---- 5. Don dep ----
Remove-Item $winZip, $macZip -ErrorAction SilentlyContinue
git fetch --tags
Write-Host "XONG: release v$Version da len GitHub"
