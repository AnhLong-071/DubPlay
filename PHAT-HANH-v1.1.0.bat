@echo off
rem PHAT-HANH-v1.1.0.bat — double-click file nay de build + phat hanh
rem DubPlay v1.1.0 len GitHub (Windows + macOS AppleSilicon + macOS Intel).
rem Khong can go lenh gi ca.
chcp 65001 >nul
title Phat hanh DubPlay v1.1.0
echo.
echo   ==============================================
echo    DANG BUILD VA PHAT HANH DUBPLAY v1.1.0
echo   ==============================================
echo.
echo   Lan dau chay se tai mpv macOS (~50MB x 2 ban) - cho vai phut.
echo   Cua so nay tu hien ket qua. KHONG dong cua so nay khi dang chay.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
echo.
echo   ==============================================
if errorlevel 1 (
    echo    CO LOI - copy man hinh nay gui lai cho Claude de sua
) else (
    echo    XONG - kiem tra dong "XONG: release v1.1.0" phia tren
)
echo   ==============================================
echo.
echo   Nhan phim bat ky de dong cua so...
pause >nul
