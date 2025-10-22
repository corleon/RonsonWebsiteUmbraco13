# Configuration
$sourceDir = "renamed_files"
$targetDir = "wwwroot/media"  # Umbraco media folder

Write-Host "Starting media files copy process...`n" -ForegroundColor Green

try {
    # 1. Check if source directory exists
    if (-not (Test-Path $sourceDir)) {
        throw "Directory $sourceDir not found!"
    }
    
    # 2. Create target directory if not exists
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "Created directory: $targetDir`n" -ForegroundColor Yellow
    }
    
    # 3. Get all files
    $files = Get-ChildItem -Path $sourceDir -File
    
    Write-Host "Found $($files.Count) files`n" -ForegroundColor Cyan
    
    # 4. Statistics
    $successCount = 0
    $errorCount = 0
    $createdFolders = @{}
    
    Write-Host "Copying files...`n" -ForegroundColor Cyan
    
    # 5. Process each file
    foreach ($file in $files) {
        try {
            # Extract Message_ID from filename (format: 000002_originalname.jpg)
            if ($file.Name -match '^(\d+)_(.+)$') {
                $messageId = $matches[1]
                $originalFileName = $file.Name
                
                # Create message folder if needed
                $messageFolderPath = Join-Path $targetDir $messageId
                
                if (-not $createdFolders.ContainsKey($messageId)) {
                    if (-not (Test-Path $messageFolderPath)) {
                        New-Item -ItemType Directory -Path $messageFolderPath -Force | Out-Null
                        Write-Host "Created folder: media/$messageId/" -ForegroundColor Gray
                    }
                    $createdFolders[$messageId] = $true
                }
                
                # Copy file
                $targetFilePath = Join-Path $messageFolderPath $originalFileName
                Copy-Item -LiteralPath $file.FullName -Destination $targetFilePath -Force
                
                $successCount++
                
                # Show progress every 50 files
                if ($successCount % 50 -eq 0) {
                    Write-Host "Copied: $successCount files..." -ForegroundColor Gray
                }
                
            } else {
                Write-Host "Warning: Could not parse Message_ID from filename: $($file.Name)" -ForegroundColor Yellow
            }
            
        } catch {
            $errorCount++
            Write-Host "Error copying $($file.Name): $_" -ForegroundColor Red
        }
    }
    
    # 6. Final statistics
    Write-Host "`n$('=' * 50)" -ForegroundColor White
    Write-Host "FINAL STATISTICS:" -ForegroundColor Yellow
    Write-Host "$('=' * 50)" -ForegroundColor White
    Write-Host "Successfully copied: $successCount files" -ForegroundColor Green
    Write-Host "Created folders: $($createdFolders.Count)" -ForegroundColor Cyan
    Write-Host "Errors: $errorCount" -ForegroundColor Red
    Write-Host "Total files processed: $($files.Count)" -ForegroundColor Cyan
    Write-Host "$('=' * 50)" -ForegroundColor White
    
    # 7. Show folder structure sample
    Write-Host "`nFolder structure created:" -ForegroundColor Cyan
    Get-ChildItem $targetDir -Directory | Select-Object -First 5 | ForEach-Object {
        $fileCount = (Get-ChildItem $_.FullName -File).Count
        Write-Host "  media/$($_.Name)/ ($fileCount files)" -ForegroundColor Gray
    }
    
    Write-Host "`nDone! Files copied to: $targetDir" -ForegroundColor Green
    
} catch {
    Write-Host "`nCritical error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")