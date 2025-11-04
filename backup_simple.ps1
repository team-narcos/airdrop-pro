# Simple Backup Script for iOS 18 AirDrop Project

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Backup of iOS 18 AirDrop App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Define paths
$projectPath = "C:\Users\Abhijeet Nardele\Projects\my-app"
$desktopPath = "C:\Users\Abhijeet Nardele\OneDrive\Desktop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$zipFileName = "iOS18_AirDrop_App_Backup_$timestamp.zip"
$zipPath = Join-Path $desktopPath $zipFileName

Write-Host "Project: $projectPath" -ForegroundColor Yellow
Write-Host "Backup:  $zipPath" -ForegroundColor Yellow
Write-Host ""

# Check paths exist
if (-not (Test-Path $projectPath)) {
    Write-Host "ERROR: Project not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $desktopPath)) {
    Write-Host "ERROR: Desktop not found!" -ForegroundColor Red  
    exit 1
}

Write-Host "Creating backup..." -ForegroundColor Green
Write-Host "This will take a moment..." -ForegroundColor White

try {
    # Use Compress-Archive to create ZIP
    $filesToBackup = @(
        "lib",
        "test", 
        "web",
        "windows",
        "android",
        "ios",
        "pubspec.yaml",
        "pubspec.lock",
        "analysis_options.yaml",
        "README.md",
        "*.md",
        "*.ps1"
    )
    
    # Get all items to backup (avoid duplicates)
    $itemsToCompress = @()
    $addedPaths = @{}
    foreach ($pattern in $filesToBackup) {
        $items = Get-ChildItem -Path $projectPath -Name $pattern -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $fullPath = Join-Path $projectPath $item
            if ((Test-Path $fullPath) -and (-not $addedPaths.ContainsKey($fullPath))) {
                $itemsToCompress += $fullPath
                $addedPaths[$fullPath] = $true
            }
        }
    }
    
    # Create the ZIP file
    if ($itemsToCompress.Count -gt 0) {
        Compress-Archive -Path $itemsToCompress -DestinationPath $zipPath -CompressionLevel Optimal -Force
        
        # Get file info
        $zipFile = Get-Item $zipPath
        $sizeMB = [math]::Round($zipFile.Length / 1MB, 2)
        
        Write-Host ""
        Write-Host "SUCCESS: Backup created!" -ForegroundColor Green
        Write-Host "Location: $zipPath" -ForegroundColor White
        Write-Host "Size: $sizeMB MB" -ForegroundColor White
        Write-Host "Time: $timestamp" -ForegroundColor White
        
        Write-Host ""
        Write-Host "Backup includes:" -ForegroundColor Cyan
        Write-Host "- All source code (lib, test, web)" -ForegroundColor White
        Write-Host "- Configuration files" -ForegroundColor White  
        Write-Host "- Documentation" -ForegroundColor White
        Write-Host "- Scripts and utilities" -ForegroundColor White
        
        Write-Host ""
        Write-Host "Your project is safely backed up!" -ForegroundColor Green
        
    } else {
        Write-Host "ERROR: No files found to backup!" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    exit 1
}

Write-Host ""
Write-Host "Backup location:" -ForegroundColor Cyan
Write-Host $zipPath -ForegroundColor Yellow