@echo off
rem The Brain, Phase 0: write today's read-only briefing and open it.
where node >nul 2>nul || (echo Node.js is not installed or not on PATH. Install it from nodejs.org, then run this again. & pause & exit /b 1)
node "%~dp0brain\briefing.js"
if /i "%~1"=="quiet" exit /b %errorlevel%
start "" "%~dp0briefings\latest.md"
