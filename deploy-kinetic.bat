@echo off
setlocal

cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy-kinetic.ps1" %*
set "PASTA_DEPLOY_EXIT=%ERRORLEVEL%"

if not "%PASTA_DEPLOY_EXIT%"=="0" (
    echo.
    echo Pasta deployment stopped with exit code %PASTA_DEPLOY_EXIT%.
    pause
)

exit /b %PASTA_DEPLOY_EXIT%
