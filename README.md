# DubPlay

> 🇻🇳 **Tiếng Việt** (bản chính) · [🇬🇧 English](README.en.md)

Player xem video **kèm audio lồng tiếng** với trải nghiệm như đang dùng extension trên YouTube: tiếng gốc **tự nhỏ xuống khi giọng lồng tiếng nói**, im lặng thì tiếng gốc về 100% — không phải trộn âm thanh trước, không convert video.

Xây trên [mpv](https://mpv.io) (player mã nguồn mở chơi được MỌI định dạng, kể cả DivX/codec cũ) + giao diện [uosc](https://github.com/tomasklaen/uosc) tùy biến.

## 📥 Tải & cài

Tải bản mới nhất tại **[Releases](https://github.com/AnhLong-071/DubPlay/releases/latest)**.

### Windows (không cần quyền admin)

1. Tải **`DubPlay-Windows-*.zip`** và giải nén
2. **Double-click `Cai-dat-DubPlay.bat`** — xong (tự đăng ký Open with + Start Menu)
3. Right-click video → **Open with → DubPlay**, và có shortcut **DubPlay** trong Start Menu

> Cách khác nếu thích: mở PowerShell trong thư mục vừa giải nén và chạy
> `powershell -ExecutionPolicy Bypass -File install-windows.ps1`

### macOS (kiểu app chuẩn — không cần Terminal, không cần Homebrew)

1. Tải đúng bản cho máy:
   - **`DubPlay-macOS-AppleSilicon-*.zip`** — Mac từ 2021 trở đi (chip Apple M1/M2/M3/M4)
   - **`DubPlay-macOS-Intel-*.zip`** — Mac cũ dùng chip Intel
   - Không chắc? Bấm logo Apple → **Giới thiệu về Mac này**: thấy "Apple M..." = Apple Silicon, không thấy = Intel
2. Giải nén → **kéo `DubPlay.app` vào thư mục Applications**
3. Lần đầu mở: **chuột phải DubPlay.app → Open → Open** (xác nhận 1 lần duy nhất — app chưa ký số, chính [mpv](https://mpv.io) gốc cũng phát hành kiểu này)
4. Mở DubPlay từ Launchpad/Applications → trình duyệt video tự hiện → chọn video xem

Sau đó: đặt `dub_audio*.wav` + `.srt` cạnh video là tự nhận; trong player bấm `a` đổi audio, `s` phụ đề, `o` mở video khác.

> Ai quen dòng lệnh: vẫn có cách cài qua Homebrew — clone repo và chạy `bash install-mac.sh`.

## ✨ Tính năng

- **Tự động**: đặt file `dub_audio*.wav` (xuất từ extension AI Sub Translator) và `.srt` cạnh video → mở lên là tự ghép
- **Trình duyệt file ngay trong app** (không mở cửa sổ ngoài): file hiện lên đầu, icon có màu theo loại, ghim "Ổ đĩa · Chỗ nhanh" để nhảy sang ổ khác bằng 1 lần bấm, có ô tìm kiếm
- **Chỉnh trực tiếp khi xem**: `d`/`D` đậm/nhạt mức duck tiếng gốc, `x`/`X` nhỏ/to âm lượng giọng dub
- Chạy được trên **Windows và macOS**

## ⌨️ Cách dùng

| Phím / nút | Chức năng |
|---|---|
| `a` | Chọn audio lồng tiếng (WAV/MP3/M4A...) — trình duyệt mở tại thư mục video |
| `s` | Chọn phụ đề (SRT/VTT/ASS...) |
| `o` | Mở video khác |
| `d` / `D` | Đậm / nhạt mức hạ tiếng gốc khi dub nói |
| `x` / `X` | Nhỏ / to âm lượng giọng dub |
| Chuột phải | Menu đầy đủ |

Mở app không kèm video → trình duyệt chọn video tự mở (bắt đầu từ trang ổ đĩa).

## 🔨 Build từ source

Trên máy đã cài mpv (Windows: `winget install shinchiro.mpv`):

```powershell
powershell -ExecutionPolicy Bypass -File assemble.ps1   # dựng DubPlay.zip (mpv + cấu hình)
```

macOS chỉ cần clone repo và chạy `bash install-mac.sh`.

## ⚖️ Giấy phép & ghi nguồn

- Dự án này: **GPL-3.0** (xem [LICENSE](LICENSE))
- [mpv](https://mpv.io) — GPL-2.0+/LGPL; bản Windows trong zip build từ [shinchiro builds](https://github.com/shinchiro/mpv-winbuild-cmake)
- [uosc](https://github.com/tomasklaen/uosc) của tomasklaen — GPL-3.0; bản trong repo có patch nhỏ cho phép tô màu icon trong menu (`icon_color`)

> Zip build sẵn chứa binary mpv — khi phân phát lại zip, hãy ghi rõ nguồn mpv/shinchiro ở trên (nghĩa vụ GPL).
