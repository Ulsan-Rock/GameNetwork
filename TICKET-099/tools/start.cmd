@echo off
rem TICKET-099: open server, LoadTester, TestClient windows. Usage: tools\start [-Client 2] [-Only Server] [-NoBuild]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1" %*
