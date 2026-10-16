#!/bin/bash
# DubPlay (macOS) — double-click: trình duyệt video mở sẵn trong app.
# Kéo video thả vào file này cũng chạy. Yêu cầu: đã chạy install-mac.sh.
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ $# -eq 0 ]; then
  exec mpv --idle
else
  exec mpv -- "$@"
fi
