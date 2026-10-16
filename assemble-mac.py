#!/usr/bin/env python3
"""Đóng gói DubPlay-macOS.zip có sẵn quyền chạy (+x) cho .sh/.command.

PowerShell Compress-Archive không lưu permission Unix — .command sau khi
giải nén trên macOS sẽ KHÔNG double-click được ("permission denied").
Python zipfile đặt create_system=3 (unix) + external_attr=0755 cho các
entry script nên macOS khôi phục đúng quyền khi giải nén.

Cách chạy:  python assemble-mac.py [ten-file-dau-ra.zip]
"""
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
EXEC_FILES = ["install-mac.sh", "Cai-dat-DubPlay.command", "DubPlay.command"]
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(ROOT, "DubPlay-macOS.zip")


def add_exec(z, name):
    """Thêm 1 file ở gốc zip với quyền 0755 (đủ double-click trên macOS)."""
    src = os.path.join(ROOT, name)
    info = zipfile.ZipInfo.from_file(src, name)
    info.create_system = 3  # unix — buộc extractor hiểu external_attr là mode Unix
    info.external_attr = 0o755 << 16
    with open(src, "rb") as fh:
        z.writestr(info, fh.read())


def add_tree(z, src_dir, arc_prefix):
    """Thêm cây thư mục (config/data — không cần quyền đặc biệt)."""
    for base, _dirs, files in os.walk(src_dir):
        for f in sorted(files):
            full = os.path.join(base, f)
            arc = os.path.join(arc_prefix, os.path.relpath(full, src_dir)).replace(os.sep, "/")
            z.write(full, arc)


if os.path.exists(OUT):
    os.remove(OUT)
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    for name in EXEC_FILES:
        add_exec(z, name)
    add_tree(z, os.path.join(ROOT, "portable_config"), "portable_config")

# Tự kiểm: đọc lại header zip xác nhận quyền đã ghi đúng.
with zipfile.ZipFile(OUT) as z:
    bad = [n for n in EXEC_FILES
           if (z.getinfo(n).external_attr >> 16) & 0o777 != 0o755]
    if bad:
        sys.exit("LOI: entry thieu quyen 0755: %s" % bad)
print("XONG: %s (%d bytes) — .sh/.command co quyen +x" % (OUT, os.path.getsize(OUT)))
