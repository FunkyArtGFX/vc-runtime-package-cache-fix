@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ==================================================
REM Universal Microsoft Visual C++ Package Cache Fix
REM ==================================================
REM Fixes missing vc_runtimeMinimum_x64.msi /
REM vc_runtimeAdditional_x64.msi errors
REM on Windows 10 / 11 systems.
REM
REM Typical error:
REM "The path C:\ProgramData\Package Cache\{GUID}\v14.xx.xxxxx\..."
REM cannot be found.
REM
REM This script:
REM - Downloads the official Microsoft VC++ Redistributable
REM - Extracts the real MSI files using /layout
REM - Restores missing Package Cache entries automatically
REM ==================================================

set "VC_URL=https://aka.ms/vc14/vc_redist.x64.exe"
set "WORKDIR=%TEMP%\VC_RUNTIME_FIX"
set "INSTALLER=%WORKDIR%\vc_redist.x64.exe"
set "EXTRACTDIR=%WORKDIR%\extract"
set "CACHE_ROOT=C:\ProgramData\Package Cache"

REM ================= ADMIN CHECK =====================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ERROR: Please run this script AS ADMINISTRATOR!
    pause
    exit /b 1
)

echo ▶ Starting Universal VC++ Package Cache Fix
echo.

REM ================= SETUP ===========================
mkdir "%WORKDIR%" "%EXTRACTDIR%" 2>nul

REM ================= DOWNLOAD ========================
if not exist "%INSTALLER%" (
    echo ▶ Downloading official Microsoft VC++ Redistributable...
    powershell -Command ^
      "Invoke-WebRequest -Uri '%VC_URL%' -OutFile '%INSTALLER%'"
)

REM ================= EXTRACT =========================
echo ▶ Extracting MSI files (this may take a moment)...
"%INSTALLER%" /layout "%EXTRACTDIR%" /quiet

REM ================= COPY LOGIC ======================
echo ▶ Restoring missing Package Cache entries...

for /D %%G in ("%CACHE_ROOT%\{*}") do (
    for /D %%V in ("%%G\v14.*") do (

        REM Minimum Runtime
        if exist "%EXTRACTDIR%\packages\vcRuntimeMinimum_amd64\vc_runtimeMinimum_x64.msi" (
            mkdir "%%V\packages\vcRuntimeMinimum_amd64" 2>nul
            copy "%EXTRACTDIR%\packages\vcRuntimeMinimum_amd64\vc_runtimeMinimum_x64.msi" ^
                 "%%V\packages\vcRuntimeMinimum_amd64\" /Y >nul
        )

        REM Additional Runtime
        if exist "%EXTRACTDIR%\packages\vcRuntimeAdditional_amd64\vc_runtimeAdditional_x64.msi" (
            mkdir "%%V\packages\vcRuntimeAdditional_amd64" 2>nul
            copy "%EXTRACTDIR%\packages\vcRuntimeAdditional_amd64\vc_runtimeAdditional_x64.msi" ^
                 "%%V\packages\vcRuntimeAdditional_amd64\" /Y >nul
        )
    )
)

REM ================= DONE ============================
echo.
echo ✅ Universal VC++ Package Cache repair completed.
echo ▶ You can now restart the application or installer
echo ▶ that previously failed.
echo.

pause
