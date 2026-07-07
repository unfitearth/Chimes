@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0chimes.ps1" off
ping -n 3 127.0.0.1 >nul
