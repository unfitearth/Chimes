@echo off
rem Mute for a while: pass a duration (chimes-timer 45m) or get prompted.
set "dur=%~1"
if "%dur%"=="" set /p "dur=Mute for how long? (e.g. 30m, 2h, 1h30m) [30m]: "
if "%dur%"=="" set "dur=30m"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0chimes.ps1" off %dur%
ping -n 3 127.0.0.1 >nul
