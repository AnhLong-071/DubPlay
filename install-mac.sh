#!/bin/bash
# DubPlay cho macOS — cài mpv (nếu chưa có) + đặt cấu hình DubPlay vào chỗ chuẩn.
# Cách chạy: mở Terminal trong thư mục này và gõ:  bash install-mac.sh
set -e

# 1. mpv (player chơi được MỌI định dạng video)
if ! command -v mpv >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "[LỖI] Chưa có Homebrew. Cài trước theo hướng dẫn tại https://brew.sh rồi chạy lại."
    exit 1
  fi
  echo "Đang cài mpv qua Homebrew (lần đầu có thể mất vài phút)..."
  brew install mpv
fi

# 2. Cấu hình DubPlay: scripts + fonts + mpv.conf vào ~/.config/mpv
SRC="$(cd "$(dirname "$0")" && pwd)/portable_config"
CFG="$HOME/.config/mpv"
mkdir -p "$CFG"
cp -R "$SRC/." "$CFG/"

# 3. Cấp quyền chạy cho launcher (nếu kèm theo)
CMD="$SRC/../DubPlay.command"
[ -f "$CMD" ] && chmod +x "$(dirname "$SRC")/DubPlay.command"

echo ""
echo "XONG ✓"
echo "Cách dùng:"
echo "  · Kéo video thả vào DubPlay.command (nếu có), hoặc trong Terminal:  mpv ten_video.mp4"
echo "  · Đặt file dub_audio*.wav và .srt CẠNH video là tự nhận"
echo "  · Trong player: a = chọn audio lồng tiếng · s = phụ đề · o = mở video khác"
