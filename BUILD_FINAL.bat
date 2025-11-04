@echo off
echo ========================================
echo  AirDrop App - Final Build Script
echo ========================================
echo.

REM Define paths
set "SOURCE_DIR=%CD%"
set "BUILD_DIR=C:\temp-build\airdrop-app"
set "APK_OUTPUT=%BUILD_DIR%\build\app\outputs\flutter-apk\app-release.apk"

echo Step 1: Creating temporary build directory...
if exist "%BUILD_DIR%" (
    echo Removing old build directory...
    rmdir /s /q "%BUILD_DIR%"
)
mkdir "%BUILD_DIR%"

echo.
echo Step 2: Copying project files (this may take a moment)...
xcopy "%SOURCE_DIR%\*" "%BUILD_DIR%\" /E /I /Y /Q
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to copy files!
    pause
    exit /b 1
)

echo.
echo Step 3: Building APK from temporary location...
cd /d "%BUILD_DIR%"

flutter clean
flutter pub get
flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo  BUILD FAILED!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo Step 4: Copying APK back to original location...
copy "%APK_OUTPUT%" "%SOURCE_DIR%\app-release.apk" /Y
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Could not copy APK to source directory
    echo APK is available at: %APK_OUTPUT%
)

echo.
echo ========================================
echo  BUILD SUCCESSFUL!
echo ========================================
echo.
echo APK Locations:
echo 1. Original: %SOURCE_DIR%\app-release.apk
echo 2. Build: %APK_OUTPUT%
echo.
echo Opening APK location...
cd /d "%SOURCE_DIR%"
if exist "app-release.apk" (
    start "" "%SOURCE_DIR%"
) else (
    start "" "%BUILD_DIR%\build\app\outputs\flutter-apk"
)

echo.
echo Install command:
echo adb install -r app-release.apk
echo.
pause
