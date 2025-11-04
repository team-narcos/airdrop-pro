# Create Backup ZIP of iOS 18 AirDrop Project
# This script creates a complete backup of the project on Desktop

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Backup ZIP of iOS 18 AirDrop App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Define paths
$projectPath = "C:\Users\Abhijeet Nardele\Projects\my-app"
$desktopPath = "C:\Users\Abhijeet Nardele\Desktop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$zipFileName = "iOS18_AirDrop_App_Backup_$timestamp.zip"
$zipPath = Join-Path $desktopPath $zipFileName

Write-Host "Project Location: $projectPath" -ForegroundColor Yellow
Write-Host "Backup Location: $zipPath" -ForegroundColor Yellow
Write-Host ""

# Check if project directory exists
if (-not (Test-Path $projectPath)) {
    Write-Host "❌ Project directory not found at: $projectPath" -ForegroundColor Red
    exit 1
}

# Check if desktop directory exists
if (-not (Test-Path $desktopPath)) {
    Write-Host "❌ Desktop directory not found at: $desktopPath" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Creating backup ZIP file..." -ForegroundColor Green
Write-Host "This may take a few moments..." -ForegroundColor White

try {
    # Create temporary directory for clean backup
    $tempBackupPath = Join-Path $env:TEMP "airdrop_backup_temp"
    if (Test-Path $tempBackupPath) {
        Remove-Item $tempBackupPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempBackupPath -Force | Out-Null

    # Copy project files excluding unnecessary directories
    $excludePatterns = @(
        "build",
        ".dart_tool",
        ".flutter-plugins",
        ".flutter-plugins-dependencies",
        "*.log",
        "node_modules",
        "*.tmp",
        "*.temp"
    )

    Write-Host "📁 Copying project files..." -ForegroundColor Cyan

    # Use robocopy for efficient copying with exclusions
    $robocopyArgs = @(
        $projectPath,
        $tempBackupPath,
        "/MIR",
        "/XD", "build", ".dart_tool", "node_modules",
        "/XF", "*.log", "*.tmp", "*.temp",
        "/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np"
    )
    
    $robocopyResult = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -Wait -PassThru -WindowStyle Hidden
    
    # Robocopy exit codes 0-3 are success, 4+ are errors
    if ($robocopyResult.ExitCode -gt 3) {
        Write-Host "⚠️ Some files may not have been copied completely" -ForegroundColor Yellow
    }

    Write-Host "🗜️ Compressing files..." -ForegroundColor Cyan
    
    # Create the ZIP file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempBackupPath, $zipPath)

    # Clean up temporary directory
    Remove-Item $tempBackupPath -Recurse -Force

    # Get file size for confirmation
    $zipFile = Get-Item $zipPath
    $sizeMB = [math]::Round($zipFile.Length / 1MB, 2)

    Write-Host ""
    Write-Host "✅ Backup created successfully!" -ForegroundColor Green
    Write-Host "📍 Location: $zipPath" -ForegroundColor White
    Write-Host "📏 Size: $sizeMB MB" -ForegroundColor White
    Write-Host "⏰ Timestamp: $timestamp" -ForegroundColor White

    # Show what's included
    Write-Host ""
    Write-Host "Backup includes:" -ForegroundColor Cyan
    Write-Host "- All source code (lib, test, web, etc.)" -ForegroundColor White
    Write-Host "- Configuration files (pubspec.yaml, etc.)" -ForegroundColor White
    Write-Host "- Documentation and README files" -ForegroundColor White
    Write-Host "- Test scripts and utilities" -ForegroundColor White
    Write-Host "- Bug fixes and reports" -ForegroundColor White
    Write-Host ""
    Write-Host "Excluded for space:" -ForegroundColor Yellow
    Write-Host "- Build artifacts (build folder)" -ForegroundColor Gray
    Write-Host "- Dart tool cache (.dart_tool folder)" -ForegroundColor Gray
    Write-Host "- Temporary files (logs, tmp files)" -ForegroundColor Gray

    Write-Host ""
    Write-Host "SUCCESS: Your iOS 18 AirDrop App is safely backed up!" -ForegroundColor Green
    Write-Host "You can now make changes knowing you have a complete backup." -ForegroundColor White

} catch {
    Write-Host "ERROR: Error creating backup: $($_.Exception.Message)" -ForegroundColor Red
    
    # Clean up on error
    if (Test-Path $tempBackupPath) {
        Remove-Item $tempBackupPath -Recurse -Force
    }
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    exit 1
}

Write-Host ""
Write-Host "You can find your backup at:" -ForegroundColor Cyan
Write-Host $zipPath -ForegroundColor Yellow
