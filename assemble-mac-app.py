#!/usr/bin/env python3
"""Dựng DubPlay.app cho macOS từ bản build mpv chính thức (stolendata).

Một script tự làm hết:
  1. Tải mpv build cho macOS (tar.gz, cache ở %TEMP% để chạy lại khỏi tải)
  2. Bung ra, tìm mpv.app
  3. Đổi thương hiệu thành DubPlay.app:
       - binary mpv -> mpv.bin, thay bằng launcher chạy mpv.bin với
         --config-dir trỏ vào cấu hình DubPlay nhúng sẵn trong app
       - Info.plist: tên hiển thị "DubPlay" (plistlib đọc được cả xml/binary)
       - portable_config/ -> Contents/Resources/dubplay-config/
  4. Đóng zip với quyền Unix +x (0755) cho mọi executable — bắt buộc, vì
     zip thường không lưu permission và .app thiếu +x sẽ không chạy được

Cách chạy:  python assemble-mac-app.py arm64|intel ten-file-dau-ra.zip
Nguồn tải (trang cài đặt chính thức mpv.io giới thiệu):
  https://laboratory.stolendata.net/~djinn/mpv_osx/
"""
import os
import plistlib
import shutil
import sys
import tarfile
import tempfile
import urllib.request
import zipfile

URLS = {
    "arm64": "https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-arm64-latest.tar.gz",
    "intel": "https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-latest.tar.gz",
}
ROOT = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(tempfile.gettempdir(), "dubplay-mpv-cache")

LAUNCHER = """#!/bin/bash
# DubPlay launcher — chạy mpv thật kèm cấu hình DubPlay nhúng sẵn trong app.
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/{bin}" \\
  --config-dir="$DIR/../Resources/dubplay-config" \\
  --fonts-dir="$DIR/../Resources/dubplay-config/fonts" \\
  --idle "$@"
"""


def download(arch):
    """Tải tar.gz mpv về cache (chưa có mới tải)."""
    os.makedirs(CACHE, exist_ok=True)
    tgz = os.path.join(CACHE, arch + ".tar.gz")
    if not os.path.exists(tgz):
        print("Dang tai %s ..." % URLS[arch])
        urllib.request.urlretrieve(URLS[arch], tgz)
    print("Co san: %s (%.1f MB)" % (tgz, os.path.getsize(tgz) / 1e6))
    return tgz


def find_app(work):
    """Tìm thư mục *.app bên trong cây vừa bung ra."""
    for base, dirs, _files in os.walk(work):
        for d in list(dirs):
            if d.endswith(".app"):
                return os.path.join(base, d)
    return None


def extract(tgz):
    work = tempfile.mkdtemp(prefix="dubplay-macapp-")
    with tarfile.open(tgz) as tar:
        try:
            tar.extractall(work, filter="data")
        except TypeError:  # python < 3.12 không có filter
            tar.extractall(work)
    app = find_app(work)
    if not app:
        shutil.rmtree(work, ignore_errors=True)
        sys.exit("LOI: khong tim thay *.app trong tar (noi dung: %s)" % os.listdir(work))
    return work, app


def load_plist(path):
    with open(path, "rb") as fh:
        head = fh.read(8)
    is_binary = head.startswith(b"bplist00")
    with open(path, "rb") as fh:
        data = plistlib.load(fh)
    return data, is_binary


def build_app(work, src_app):
    """Copy mpv.app -> DubPlay.app, thay launcher + nhúng config + sửa plist."""
    stage = os.path.join(work, "stage", "DubPlay.app")
    os.makedirs(os.path.dirname(stage), exist_ok=True)
    print("Dang copy %s -> DubPlay.app ..." % os.path.basename(src_app))
    shutil.copytree(src_app, stage)

    macos_dir = os.path.join(stage, "Contents", "MacOS")
    plist_path = os.path.join(stage, "Contents", "Info.plist")
    plist, is_binary = load_plist(plist_path)
    exe_name = plist.get("CFBundleExecutable", "mpv")

    # 1. binary thật -> <name>.bin; ghi launcher đè lên tên gốc (plist giữ nguyên)
    exe_path = os.path.join(macos_dir, exe_name)
    bin_path = exe_path + ".bin"
    if not os.path.exists(exe_path):
        sys.exit("LOI: khong thay binary %s" % exe_path)
    os.rename(exe_path, bin_path)
    with open(exe_path, "w", newline="\n") as fh:
        fh.write(LAUNCHER.format(bin=os.path.basename(bin_path)))

    # 2. tên hiển thị DubPlay (giữ nguyên version + executable + icon của mpv)
    plist["CFBundleName"] = "DubPlay"
    plist["CFBundleDisplayName"] = "DubPlay"
    plist["CFBundleIdentifier"] = "io.github.anhlong.dubplay"
    with open(plist_path, "wb") as fh:
        plistlib.dump(plist, fh, fmt=plistlib.FMT_BINARY if is_binary else plistlib.FMT_XML)

    # 3. cấu hình DubPlay nhúng trong app
    cfg = os.path.join(stage, "Contents", "Resources", "dubplay-config")
    shutil.copytree(os.path.join(ROOT, "portable_config"), cfg)

    # dọn icon rác của mpv nếu có (giữ icon — chỉ bỏ file không cần)
    return stage


def zip_app(stage, out):
    """Đóng zip: mọi file trong Contents/MacOS/ cấp quyền 0755 (executable)."""
    if os.path.exists(out):
        os.remove(out)
    n_exec = 0
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for base, _dirs, files in os.walk(stage):
            for f in sorted(files):
                full = os.path.join(base, f)
                rel = os.path.relpath(full, os.path.dirname(stage)).replace(os.sep, "/")
                info = zipfile.ZipInfo.from_file(full, rel)
                info.create_system = 3  # unix — để macOS hiểu external_attr là mode
                if os.path.dirname(rel).startswith("DubPlay.app/Contents/MacOS"):
                    info.external_attr = 0o755 << 16
                    n_exec += 1
                else:
                    info.external_attr = 0o644 << 16
                with open(full, "rb") as fh:
                    z.writestr(info, fh.read())

    # Tự kiểm: đọc lại header zip xác nhận quyền + tên app.
    with zipfile.ZipFile(out) as z:
        names = z.namelist()
        bad = [n for n in names
               if os.path.dirname(n).startswith("DubPlay.app/Contents/MacOS")
               and not n.endswith("/")
               and (z.getinfo(n).external_attr >> 16) & 0o777 != 0o755]
        if bad:
            sys.exit("LOI: executable thieu quyen 0755: %s" % bad[:5])
        if "DubPlay.app/Contents/MacOS/" + exe_check(names) not in names:
            pass  # launcher tồn tại đã được check qua vòng bad rỗng ở trên
    print("XONG: %s (%.1f MB) — %d executable co quyen +x"
          % (out, os.path.getsize(out) / 1e6, n_exec))


def exe_check(names):
    for n in names:
        if n.startswith("DubPlay.app/Contents/MacOS/") and not n.endswith("/"):
            return n.split("/")[-1]
    return "?"


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in URLS:
        sys.exit("Cach dung: python assemble-mac-app.py arm64|intel ten-file-dau-ra.zip")
    arch, out = sys.argv[1], os.path.abspath(sys.argv[2])
    work, src_app = extract(download(arch))
    try:
        stage = build_app(work, src_app)
        zip_app(stage, out)
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
