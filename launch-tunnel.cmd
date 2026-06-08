@echo off
setlocal enabledelayedexpansion
title Shirabe Cloudflare Tunnel (調べ)
cd /d "%~dp0"

echo ===================================================
echo   Shirabe Cloudflare Tunnel (調べ) Native Launcher
echo ===================================================
echo.

:: 1. Check if .env exists
if not exist .env (
    echo ERROR: .env file not found at root directory.
    echo Please run launch-windows.cmd first to perform setup.
    pause
    exit /b 1
)

:: 2. Parse TUNNEL_TOKEN from .env
set TUNNEL_TOKEN=
for /f "usebackq delims=" %%x in (".env") do (
    set "line=%%x"
    if "!line:~0,13!"=="TUNNEL_TOKEN=" (
        set "TUNNEL_TOKEN=!line:~13!"
    )
)

:: Trim spaces or quotes if any
if not "!TUNNEL_TOKEN!"=="" (
    for /f "tokens=* delims= " %%a in ("!TUNNEL_TOKEN!") do set TUNNEL_TOKEN=%%a
)

if "!TUNNEL_TOKEN!"=="" (
    echo ERROR: TUNNEL_TOKEN is not configured in your .env file.
    echo.
    echo Please open the .env file in the root directory, locate
    echo the TUNNEL_TOKEN= line under the Cloudflare section,
    echo set it to your Cloudflare Tunnel Token, and restart this script.
    echo.
    pause
    exit /b 1
)

:: 3. Check for cloudflared command
where cloudflared >nul 2>nul
if errorlevel 1 (
    :: Try standard installations
    if exist "C:\Program Files (x86)\cloudflared\cloudflared.exe" (
        set CLOUDFLARED_EXE="C:\Program Files (x86)\cloudflared\cloudflared.exe"
    ) else if exist "C:\Program Files\cloudflared\cloudflared.exe" (
        set CLOUDFLARED_EXE="C:\Program Files\cloudflared\cloudflared.exe"
    ) else (
        echo ERROR: cloudflared was not found on PATH or in standard install locations.
        echo Please download and install the Cloudflare Tunnel daemon:
        echo https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
        echo.
        pause
        exit /b 1
    )
) else (
    set CLOUDFLARED_EXE=cloudflared
)

echo ==^> Starting Cloudflare Tunnel...
echo Using token prefix: !TUNNEL_TOKEN:~0,10!***************************
echo.

!CLOUDFLARED_EXE! tunnel run --token !TUNNEL_TOKEN!
if errorlevel 1 (
    echo.
    echo ERROR: Cloudflare Tunnel exited with an error.
    pause
    exit /b !errorlevel!
)
echo.
echo Tunnel closed.
pause
