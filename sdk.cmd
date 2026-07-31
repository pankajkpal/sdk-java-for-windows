@echo off
if "%~1"=="" goto :Help

set "TMP_SDK_ENV=%TEMP%\_sdk_env_%RANDOM%.cmd"
if exist "%TMP_SDK_ENV%" del "%TMP_SDK_ENV%"

where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '%~dp0src\sdk.ps1'; sdk %* -ExportCmdScript '%TMP_SDK_ENV%'"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '%~dp0src\sdk.ps1'; sdk %* -ExportCmdScript '%TMP_SDK_ENV%'"
)

set "SDK_EXIT_CODE=%ERRORLEVEL%"

if exist "%TMP_SDK_ENV%" (
    call "%TMP_SDK_ENV%"
    del "%TMP_SDK_ENV%"
)

set "TMP_SDK_ENV="
exit /b %SDK_EXIT_CODE%

:Help
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '%~dp0src\sdk.ps1'; sdk help"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '%~dp0src\sdk.ps1'; sdk help"
)
exit /b 0