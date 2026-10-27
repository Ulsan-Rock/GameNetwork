@echo off
rem TICKET-099: apply step patch. Usage: tools\patch A7   (order: A7 A3 A1 A2 A4 A5 A6 A8, exp3 on experiment branch)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" %*
