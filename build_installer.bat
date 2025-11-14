@echo off
echo ================================================
echo  Building AirDrop Pro Installer
echo ================================================
echo.

REM Check if Inno Setup is installed
set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if not exist "%ISCC_PATH%" (
    echo ERROR: Inno Setup not found!
    echo.
    echo Please download and install Inno Setup from:
    echo https://jrsoftware.org/isdl.php
    echo.
    echo Download: innosetup-6.x.x.exe
    echo Install it and run this script again.
    echo.
    pause
    exit /b 1
)

echo Creating output directory...
if not exist "installer_output" mkdir "installer_output"

echo.
echo Compiling installer...
"%ISCC_PATH%" "installer_setup.iss"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================
    echo  SUCCESS!
    echo ================================================
    echo.
    echo Installer created: installer_output\AirDropPro_Setup.exe
    echo.
    echo You can now share this single .exe file!
    echo Users just need to run it to install the app.
    echo.
    start "" "installer_output"
) else (
    echo.
    echo ================================================
    echo  BUILD FAILED!
    echo ================================================
    echo.
)

pause
