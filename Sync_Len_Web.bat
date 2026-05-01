@echo off
echo ==============================================
echo   DONG BO GIAO DIEN TOAN CA CHEP PLAYLIST
echo ==============================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_playlist.ps1"
echo.
pause
