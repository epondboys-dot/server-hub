@echo off
rem Run the briefing every morning at 7:30. Run this once; it changes no project files.
schtasks /Create /F /SC DAILY /ST 07:30 /TN "Server Hub Daily Briefing" /TR "\"%~dp0Run-Briefing.cmd\" quiet"
echo.
echo Done. To remove it later: schtasks /Delete /TN "Server Hub Daily Briefing" /F
pause
