# Fix Dark Mode Text Colors Globally
Write-Host "Fixing dark mode text colors in all screens..." -ForegroundColor Cyan

$files = Get-ChildItem -Path "lib\screens" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Replace iOS18Colors.textPrimary with iOS18Colors.getTextPrimary(context)
    $content = $content -replace 'iOS18Colors\.textPrimary(?!Dark)', 'iOS18Colors.getTextPrimary(context)'
    
    # Replace iOS18Colors.textSecondary with iOS18Colors.getTextSecondary(context)
    $content = $content -replace 'iOS18Colors\.textSecondary(?!Dark)', 'iOS18Colors.getTextSecondary(context)'
    
    # Replace iOS18Colors.textTertiary with iOS18Colors.getTextTertiary(context)
    $content = $content -replace 'iOS18Colors\.textTertiary(?!Dark)', 'iOS18Colors.getTextTertiary(context)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "Done! All screens now support dark mode text colors." -ForegroundColor Green