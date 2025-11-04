# Quick Launch Script for iOS 18 AirDrop App
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Launching iOS 18 AirDrop App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$flutterPath = "C:\Users\Abhijeet Nardele\flutter\bin"

Write-Host "Starting app in Chrome..." -ForegroundColor Green
Write-Host "URL: http://localhost:8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "Features to test:" -ForegroundColor Cyan
Write-Host "- Premium splash screen animation" -ForegroundColor White
Write-Host "- 5-tab bottom navigation" -ForegroundColor White
Write-Host "- Discovery button with pulsing animation" -ForegroundColor White
Write-Host "- Theme switching (Settings > Theme)" -ForegroundColor White
Write-Host "- File picker and sharing" -ForegroundColor White
Write-Host "- QR code generation" -ForegroundColor White
Write-Host "- Storage visualization" -ForegroundColor White
Write-Host "- Transfer history and statistics" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Red

& "$flutterPath\flutter.bat" run -d chrome --web-port=8080