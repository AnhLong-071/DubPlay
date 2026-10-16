@echo off
rem DubPlay — player video long tieng (mpv + duck tu dong).
rem Double-click: trinh duyet video mo san ngay trong app (go de tim nhanh).
rem Keo file video tha vao file nay cung chay. Dat "dub_audio*.wav" va "*.srt"
rem canh video la tu nhan, khong can chon thu cong.
if "%~1"=="" (
  start "" "%~dp0DubPlay.exe" --idle
) else (
  start "" "%~dp0DubPlay.exe" -- %*
)
