#!/bin/bash
# DubPlay — CÀI ĐẶT: double-click file này là xong, không cần gõ lệnh.
# Cửa sổ Terminal hiện lên để báo tiến độ, tự đóng khi bạn nhấn phím.
cd "$(dirname "$0")"
echo ""
echo "  ============================================"
echo "    CÀI ĐẶT DUBPLAY CHO macOS"
echo "  ============================================"
echo ""
if bash install-mac.sh; then
  echo ""
  echo "  XONG ✓  Có thể đóng cửa sổ này."
  echo "  Cách dùng: chạy lệnh  mpv ten_video.mp4  trong Terminal,"
  echo "  hoặc kéo video thả vào file DubPlay.command."
else
  echo ""
  echo "  LỖI: cài đặt chưa xong — đọc thông báo phía trên."
fi
echo ""
echo "  Nhấn phím bất kỳ để đóng..."
read -n 1 -s
