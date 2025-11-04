# Flutter Setup and Run Script
Write-Host "Searching for Flutter installation..." -ForegroundColor Cyan

# Common Flutter installation paths
$paths = @(
    "C:\flutter\bin",
    "C:\src\flutter\bin",
    "$env:LOCALAPPDATA\flutter\bin",
    "$env:USERPROFILE\flutter\bin",
    "$env:ProgramFiles\flutter\bin"
)

$flutterPath = $null
foreach ($path in $paths) {
    if (Test-Path "$path\flutter.bat") {
        $flutterPath = $path
        Write-Host "Found Flutter at: $path" -ForegroundColor Green
        break
    }
}

if (-not $flutterPath) {
    Write-Host "Flutter not found. Please install Flutter from https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Red
    Write-Host "After installing, extract to C:\flutter and rerun this script." -ForegroundColor Yellow
    exit 1
}

# Add to current session PATH
$env:PATH = "$flutterPath;$env:PATH"

# Verify Flutter works
Write-Host "`nVerifying Flutter..." -ForegroundColor Cyan
& "$flutterPath\flutter.bat" --version

# Enable web support
Write-Host "`nEnabling web support..." -ForegroundColor Cyan
& "$flutterPath\flutter.bat" config --enable-web

# Get dependencies
Write-Host "`nGetting dependencies..." -ForegroundColor Cyan
& "$flutterPath\flutter.bat" pub get

# Skip build_runner (incompatible with Dart 3.2)
Write-Host "`nSkipping code generation (using manual stubs)..." -ForegroundColor Yellow

# Run the app
Write-Host "`nLaunching app in Chrome..." -ForegroundColor Cyan
& "$flutterPath\flutter.bat" run -d chrome
