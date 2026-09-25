@echo off
setlocal

set "VERMISHELL_ROOT=%~dp0"
if exist "%VERMISHELL_ROOT%scripts\start-server.ps1" goto launch

set "VERMISHELL_ROOT=C:\Users\mykha\OneDrive\Desktop\minecraft\servers\Vermishell\"
if exist "%VERMISHELL_ROOT%scripts\start-server.ps1" goto launch

echo Vermishell could not find scripts\start-server.ps1.
echo Keep start.bat inside the Vermishell repository, or create a shortcut to it instead of copying it.
pause
exit /b 1

:launch
cd /d "%VERMISHELL_ROOT%"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%VERMISHELL_ROOT%scripts\start-server.ps1"
set "VERMISHELL_EXIT=%ERRORLEVEL%"

if not "%VERMISHELL_EXIT%"=="0" (
    echo.
    echo Vermishell stopped with exit code %VERMISHELL_EXIT%.
    pause
)

exit /b %VERMISHELL_EXIT%
