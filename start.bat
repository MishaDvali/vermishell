@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-server.ps1"
set "VERMISHELL_EXIT=%ERRORLEVEL%"

if not "%VERMISHELL_EXIT%"=="0" (
    echo.
    echo Vermishell stopped with exit code %VERMISHELL_EXIT%.
    pause
)

exit /b %VERMISHELL_EXIT%
