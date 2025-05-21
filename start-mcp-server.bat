@echo off
echo Starting Task Master MCP Server...
echo ===================================

:: Set the absolute path to the project directory
set PROJECT_DIR=F:\SkyDrive\_AI\Cursor-Projects\claude-task-master

:: Navigate to the project directory
cd /d "%PROJECT_DIR%"

:: Run the MCP server
node mcp-server/server.js

:: Keep the window open if there's an error
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Server exited with error code %ERRORLEVEL%
    echo Press any key to close this window...
    pause > nul
) 