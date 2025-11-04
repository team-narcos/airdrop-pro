@echo off
echo ============================================
echo Starting iOS 18 AirDrop App
echo ============================================
echo.

REM Set Flutter path
set FLUTTER_PATH=C:\Users\Abhijeet Nardele\flutter\bin
set PATH=%FLUTTER_PATH%;%PATH%

echo Checking Flutter...
flutter --version
echo.

echo Running app on Chrome (port 8080)...
echo URL will be: http://localhost:8080
echo.
echo Press Ctrl+C to stop the app
echo.

flutter run -d chrome --web-port=8080

pause