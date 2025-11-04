# Simple Flutter App Launcher with Error Handling
Write-Host "Starting Flutter AirDrop App..." -ForegroundColor Green

$flutterPath = "C:\Users\Abhijeet Nardele\flutter\bin"
$env:PATH = "$flutterPath;$env:PATH"

# Check Flutter version
Write-Host "Flutter Version:" -ForegroundColor Yellow
& "$flutterPath\flutter.bat" --version

# Clean and get dependencies
Write-Host "`nCleaning project..." -ForegroundColor Yellow
& "$flutterPath\flutter.bat" clean

Write-Host "Getting dependencies..." -ForegroundColor Yellow
& "$flutterPath\flutter.bat" pub get

# Run analysis
Write-Host "`nRunning analysis..." -ForegroundColor Yellow
$analysisResult = & "$flutterPath\flutter.bat" analyze
Write-Host $analysisResult

# Try to run the app
Write-Host "`nStarting app..." -ForegroundColor Green
Write-Host "If you see errors, they will appear below:" -ForegroundColor Red

try {
    & "$flutterPath\flutter.bat" run -d chrome --web-port=8080 2>&1
} catch {
    Write-Host "Error running app: $_" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")