@echo off
rem TICKET-099: build submission folder and zip under _submit. Usage: tools\pack
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack.ps1" %*
