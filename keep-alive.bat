@echo off
title Affective Engine MCP Server (Keep-Alive)
echo ============================================
echo  Affective Engine MCP Server - Keep Alive
echo  SSE Mode - Port 8769 / Dashboard - Port 8768
echo  Press Ctrl+C to stop
echo ============================================
echo.

:loop
echo [%date% %time%] Starting server...
cd /d "C:\Users\Administrator\Desktop\affective-engine"
"C:\Users\Administrator\Desktop\affective-engine\.venv\Scripts\python.exe" -m affective_engine --sse --dashboard
echo.
echo [%date% %time%] Server exited. Restarting in 3 seconds...
timeout /t 3 /nobreak >nul
goto loop