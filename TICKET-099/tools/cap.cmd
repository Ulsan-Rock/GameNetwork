@echo off
rem TICKET-099: full-screen capture into the evidence folder. Usage: tools\cap A1_before_split [-Delay 5] [-Primary]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cap.ps1" %*
