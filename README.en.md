# DubPlay

> [🇻🇳 Tiếng Việt](README.md) (primary) · 🇬🇧 **English**

A video player with **dubbed-audio playback** that feels like using a YouTube extension: the **original audio automatically ducks when the dub voice speaks** and returns to 100% during silence — no pre-mixing, no video re-encoding.

Built on [mpv](https://mpv.io) (open-source player that plays EVERY format, including legacy DivX codecs) with a customized [uosc](https://github.com/tomasklaen/uosc) UI.

## 📥 Download & install

Get the latest build from **[Releases](https://github.com/AnhLong-071/DubPlay/releases/latest)**.

### Windows (no admin rights needed)

1. Download **`DubPlay-Windows-*.zip`** and extract it
2. Right-click `install-windows.ps1` → **Run with PowerShell** (or run in PowerShell from the extracted folder):
   ```powershell
   powershell -ExecutionPolicy Bypass -File install-windows.ps1
   ```
3. Done: right-click any video → **Open with → DubPlay**, plus a **DubPlay** shortcut in the Start Menu

### macOS

1. Download **`DubPlay-macOS-*.zip`** and extract it
2. Open Terminal in the extracted folder and run:
   ```bash
   bash install-mac.sh
   ```
   (the script installs [mpv](https://mpv.io) via [Homebrew](https://brew.sh) if missing, then places DubPlay's config)
3. Done: run `mpv` in Terminal, or drag a video onto `DubPlay.command`

## ✨ Features

- **Automatic**: put `dub_audio*.wav` (exported from the AI Sub Translator extension) and an `.srt` next to the video → attached on open
- **In-app file browser** (no external windows): files listed first, color-coded icons, a pinned "Drives · Quick places" jump at the top of every menu, built-in search
- **Live tuning while watching**: `d`/`D` stronger/softer ducking, `x`/`X` quieter/louder dub voice
- Works on **Windows and macOS**

## ⌨️ Usage

| Key / button | Action |
|---|---|
| `a` | Pick dub audio (WAV/MP3/M4A...) — browser opens in the video's folder |
| `s` | Pick subtitles (SRT/VTT/ASS...) |
| `o` | Open another video |
| `d` / `D` | Stronger / softer original-audio ducking |
| `x` / `X` | Quieter / louder dub voice |
| Right click | Full menu |

Launching the app without a video opens the in-app video browser (starting at the drives page).

## 🔨 Build from source

On a machine with mpv installed (Windows: `winget install shinchiro.mpv`):

```powershell
powershell -ExecutionPolicy Bypass -File assemble.ps1   # builds DubPlay.zip (mpv + config)
```

On macOS, clone the repo and run `bash install-mac.sh`.

## ⚖️ License & credits

- This project: **GPL-3.0** (see [LICENSE](LICENSE))
- [mpv](https://mpv.io) — GPL-2.0+/LGPL; the Windows binary in the zip comes from [shinchiro builds](https://github.com/shinchiro/mpv-winbuild-cmake)
- [uosc](https://github.com/tomasklaen/uosc) by tomasklaen — GPL-3.0; the vendored copy carries a small patch allowing per-item menu icon colors (`icon_color`)

> Prebuilt zips contain mpv binaries — if you redistribute them, keep the mpv/shinchiro credits above (GPL obligation).
