@echo off
echo Building AirDrop App APK...
echo.

REM Set environment to handle spaces in path
set "GRADLE_USER_HOME=C:\gradle-temp"
set "ANDROID_SDK_ROOT=C:\Android\sdk"

REM Clean build
echo Cleaning previous build...
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo Clean failed, continuing anyway...
)

REM Get dependencies
echo Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Failed to get dependencies!
    pause
    exit /b 1
)

REM Build APK (single universal APK to avoid path issues)
echo Building release APK...
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Opening output folder...
start "" "build\app\outputs\flutter-apk"
pause
