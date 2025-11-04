# Fix and Upgrade Script
Write-Host "=== AirDrop App Fix & Upgrade ===" -ForegroundColor Cyan

# Find Flutter
$flutterPath = "C:\Users\Abhijeet Nardele\flutter\bin"
if (-not (Test-Path "$flutterPath\flutter.bat")) {
    $flutterPath = "C:\flutter\bin"
}

Write-Host "`nUpgrading Flutter..." -ForegroundColor Yellow
& "$flutterPath\flutter.bat" upgrade --force

Write-Host "`nCleaning project..." -ForegroundColor Yellow
& "$flutterPath\flutter.bat" clean

Write-Host "`nGetting dependencies..." -ForegroundColor Yellow
& "$flutterPath\flutter.bat" pub get

Write-Host "`nEnabling web..." -ForegroundColor Yellow
& "$flutterPath\flutter.bat" config --enable-web

Write-Host "`nLaunching app..." -ForegroundColor Green
& "$flutterPath\flutter.bat" run -d chrome
