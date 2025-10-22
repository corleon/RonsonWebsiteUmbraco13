# Configuration
$xmlFile = "Filetable-273-part4.xml"
$sourceDir = "netcat_files.266.292"
$targetDir = "renamed_files_part4"

Write-Host "Starting file renaming process...`n" -ForegroundColor Green

try {
    # 1. Check if XML file exists
    if (-not (Test-Path $xmlFile)) {
        throw "File $xmlFile not found!"
    }
    
    # 2. Check if source directory exists
    if (-not (Test-Path $sourceDir)) {
        throw "Directory $sourceDir not found!"
    }
    
    Write-Host "Reading XML: $xmlFile" -ForegroundColor Cyan
    
    # 3. Load and parse XML
    [xml]$xml = Get-Content $xmlFile -Encoding UTF8
    $rows = $xml.root.row
    
    Write-Host "Found records in XML: $($rows.Count)`n" -ForegroundColor Green
    
    # 4. Create target directory
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
        Write-Host "Created directory: $targetDir`n" -ForegroundColor Yellow
    }
    
    # 5. Statistics
    $successCount = 0
    $notFoundCount = 0
    $errorCount = 0
    $notFoundFiles = @()
    
    Write-Host "Starting renaming...`n" -ForegroundColor Cyan
    
    # 6. Process each file
    foreach ($row in $rows) {
        $realName = $row.Real_Name
        $virtName = $row.Virt_Name
        $messageId = $row.Message_ID
        
        # Format: 000002_originalname.jpg (6 digits for Message_ID)
        $paddedMessageId = $messageId.PadLeft(6, '0')
        $newFileName = "${paddedMessageId}_${realName}"
        
        $sourceFile = Join-Path $sourceDir $virtName
        $targetFile = Join-Path $targetDir $newFileName
        
        try {
            # Check if source file exists
            if (-not (Test-Path $sourceFile)) {
                $notFoundCount++
                $notFoundFiles += @{
                    virtName = $virtName
                    realName = $realName
                    messageId = $messageId
                    newFileName = $newFileName
                }
                continue
            }
            
            # Copy file with new name
            Copy-Item -Path $sourceFile -Destination $targetFile -Force
            $successCount++
            
            # Show progress every 10 files
            if ($successCount % 10 -eq 0) {
                Write-Host "Processed: $successCount files" -ForegroundColor Gray
            }
            
        } catch {
            $errorCount++
            Write-Host "Error processing $newFileName : $_" -ForegroundColor Red
        }
    }
    
    # 7. Final statistics
    Write-Host "`n$('=' * 50)" -ForegroundColor White
    Write-Host "FINAL STATISTICS:" -ForegroundColor Yellow
    Write-Host "$('=' * 50)" -ForegroundColor White
    Write-Host "Successfully renamed: $successCount" -ForegroundColor Green
    Write-Host "Files not found: $notFoundCount" -ForegroundColor Yellow
    Write-Host "Copy errors: $errorCount" -ForegroundColor Red
    Write-Host "Total records in XML: $($rows.Count)" -ForegroundColor Cyan
    Write-Host "$('=' * 50)" -ForegroundColor White
    
    # 8. Show examples of renamed files
    Write-Host "`nExamples of renamed files:" -ForegroundColor Cyan
    Get-ChildItem $targetDir | Select-Object -First 5 | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }
    
    # 9. Save list of not found files
    if ($notFoundFiles.Count -gt 0) {
        $reportFile = "not_found_part1.json"
        $notFoundFiles | ConvertTo-Json | Out-File $reportFile -Encoding UTF8
        Write-Host "`nList of not found files saved: $reportFile" -ForegroundColor Yellow
        
        Write-Host "`nExamples of not found files:" -ForegroundColor Yellow
        $notFoundFiles | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.virtName) -> $($_.newFileName) (Message ID: $($_.messageId))" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nDone! Files saved in: $targetDir" -ForegroundColor Green
    
} catch {
    Write-Host "`nCritical error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")