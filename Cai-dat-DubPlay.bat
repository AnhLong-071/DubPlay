@echo off
rem Cai dat DubPlay — CHI CAN DOUBLE-CLICK file nay.
rem No go install-windows.ps1 voi che do cho phep chay script (Bypass)
rem de khong bi Windows chan "running scripts is disabled".
chcp 65001 >nul
title Cai dat DubPlay
echo.
echo   ============================================
echo    DANG CAI DAT DUBPLAY CHO BAN...
echo   ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows.ps1"
echo.
echo   Nhan phim bat ky de dong cua so...
pause >nul
