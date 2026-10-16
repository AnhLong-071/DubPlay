#!/bin/bash
# install-mac.sh — cài DubPlay lên macOS.
# Người dùng thường chỉ cần double-click "Cai-dat-DubPlay.command" (file này
# được gọi từ đó). Việc nó làm, in tiến độ từng bước:
#   1. Cài mpv qua Homebrew nếu chưa có
#   2. Đặt cấu hình DubPlay (scripts + fonts) vào ~/.config/mpv
#   3. Cấp quyền chạy cho launcher
set -e

echo "[1/3] Kiểm tra player mpv..."
if ! command -v mpv >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo ""
    echo "[LỖI] Chưa có Homebrew — cần cài trước theo hướng dẫn tại https://brew.sh"
    echo "      (mở Terminal, copy dòng lệnh /bin/bash -c \"\$(curl ...)\" trên trang đó,"
    echo "       chạy xong quay lại double-click Cai-dat-DubPlay.command lần nữa)"
    exit 1
  fi
  echo "      Đang cài mpv qua Homebrew (lần đầu có thể mất vài phút)..."
  brew install mpv
else
  echo "      Đã có mpv ✓"
fi

echo "[2/3] Đặt cấu hình DubPlay vào ~/.config/mpv..."
SRC="$(cd "$(dirname "$0")" && pwd)/portable_config"
CFG="$HOME/.config/mpv"
mkdir -p "$CFG"
cp -R "$SRC/." "$CFG/"

echo "[3/3] Cấp quyền chạy cho launcher..."
DIR="$(cd "$(dirname "$0")" && pwd)"
for f in "Cai-dat-DubPlay.command" "DubPlay.command"; do
  [ -f "$DIR/$f" ] && chmod +x "$DIR/$f"
done

echo ""
echo "XONG ✓"
echo "Cách dùng:"
echo "  · Trong Terminal:  mpv ten_video.mp4"
echo "  · Kéo video thả vào DubPlay.command"
echo "  · Đặt file dub_audio*.wav và .srt CẠNH video là tự nhận"
echo "  · Trong player: a = chọn audio lồng tiếng · s = phụ đề · o = mở video khác"
