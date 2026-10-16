# DubPlay

Player xem video **kèm audio lồng tiếng** với trải nghiệm như đang dùng extension trên YouTube: tiếng gốc **tự nhỏ xuống khi giọng lồng tiếng nói**, im lặng thì tiếng gốc về 100% — không phải trộn âm thanh trước, không convert video.

Xây trên [mpv](https://mpv.io) (player mã nguồn mở chơi được MỌI định dạng, kể cả DivX/codec cũ) + giao diện [uosc](https://github.com/tomasklaen/uosc) tùy biến.

## Tính năng

- **Tự động**: đặt file `dub_audio*.wav` (xuất từ extension AI Sub Translator) và `.srt` cạnh video → mở lên là tự ghép
- **Trình duyệt file ngay trong app** (không mở cửa sổ ngoài): file hiện lên đầu, icon có màu theo loại, ghim "Ổ đĩa · Chỗ nhanh" để nhay sang ổ khác bằng 1 lần bấm, có ô tìm kiếm
- **Chỉnh trực tiếp khi xem**: `d`/`D` đậm/nhạt mức duck tiếng gốc, `x`/`X` nhỏ/to âm lượng giọng dub
- Chạy được trên **Windows và macOS**

## Cài đặt

### Windows (không cần quyền admin)

Cách 1 — tải `DubPlay.zip` ở [Releases](../../releases), giải nén, chạy `install-windows.ps1`:

```powershell
powershell -ExecutionPolicy Bypass -File install-windows.ps1
```

Cài vào `%LOCALAPPDATA%\DubPlay`, đăng ký vào menu "Open with" và Start Menu.

Cách 2 — tự build từ source (cần cài [mpv](https://mpv.io/installation/) qua `winget install shinchiro.mpv`):

```powershell
powershell -ExecutionPolicy Bypass -File assemble.ps1        # dựng DubPlay.zip
powershell -ExecutionPolicy Bypass -File install-windows.ps1 # cài
```

### macOS

```bash
brew install mpv        # nếu chưa có mpv
bash install-mac.sh
```

## Cách dùng

| Phím / nút | Chức năng |
|---|---|
| `a` | Chọn audio lồng tiếng (WAV/MP3/M4A...) — trình duyệt mở tại thư mục video |
| `s` | Chọn phụ đề (SRT/VTT/ASS...) |
| `o` | Mở video khác |
| `d` / `D` | Đậm / nhạt mức hạ tiếng gốc khi dub nói |
| `x` / `X` | Nhỏ / to âm lượng giọng dub |
| Chuột phải | Menu đầy đủ |

Mở app không kèm video → trình duyệt chọn video tự mở (bắt đầu từ trang ổ đĩa).

## Build bản phân phối

Chạy `assemble.ps1` trên máy đã cài mpv → tạo `DubPlay.zip` (mpv + cấu hình DubPlay) để chia sẻ.

## Giấy phép & ghi nguồn

- Dự án này: **GPL-3.0** (xem [LICENSE](LICENSE))
- [mpv](https://mpv.io) — GPL-2.0+/LGPL; bản Windows trong zip build từ [shinchiro builds](https://github.com/shinchiro/mpv-winbuild-cmake)
- [uosc](https://github.com/tomasklaen/uosc) của tomasklaen — GPL-3.0; bản trong repo có patch nhỏ cho phép tô màu icon trong menu (`icon_color`)

> Zip build sẵn chứa binary mpv — khi phân phát zip, hãy ghi rõ nguồn mpv/shinchiro ở trên (nghĩa vụ GPL).
