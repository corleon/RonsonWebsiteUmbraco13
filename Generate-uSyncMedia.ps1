# Configuration
$sourceDir = "renamed_files"
$outputDir = "usync/v9/Media"
$mappingFile = "media_mapping_all.json"

Write-Host "Starting uSync Media generation...`n" -ForegroundColor Green

# Function to generate deterministic GUID from string
function Get-DeterministicGuid {
    param([string]$inputString)
    
    # Debug - check what we received
    if ([string]::IsNullOrEmpty($inputString)) {
        throw "ERROR: Empty input string for GUID generation!"
    }
    
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($inputString))
    
    # Convert hash bytes to hex string
    $hexString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    
    # Format as GUID (8-4-4-4-12)
    $guid = $hexString.Substring(0,8) + "-" + 
            $hexString.Substring(8,4) + "-" + 
            $hexString.Substring(12,4) + "-" + 
            $hexString.Substring(16,4) + "-" + 
            $hexString.Substring(20,12)
    
    return $guid
}

# Function to get file extension
function Get-FileExtension {
    param([string]$filename)
    return [System.IO.Path]::GetExtension($filename).TrimStart('.')
}

# Function to get MIME type
function Get-MimeType {
    param([string]$extension)
    
    $mimeTypes = @{
        'jpg' = 'image/jpeg'
        'jpeg' = 'image/jpeg'
        'png' = 'image/png'
        'gif' = 'image/gif'
        'bmp' = 'image/bmp'
        'webp' = 'image/webp'
        'svg' = 'image/svg+xml'
    }
    
    $ext = $extension.ToLower()
    if ($mimeTypes.ContainsKey($ext)) {
        return $mimeTypes[$ext]
    }
    return 'application/octet-stream'
}

# Function to create uSync Media XML
function New-uSyncMediaXml {
    param(
        [string]$filename,
        [string]$guid,
        [string]$filepath,
        [int]$fileSize
    )
    
    $extension = Get-FileExtension $filename
    $mimeType = Get-MimeType $extension
    $createDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    
    # Extract Message_ID from filename (format: 000002_originalname.jpg)
    $messageId = "0"
    if ($filename -match '^(\d+)_') {
        $messageId = $matches[1]
    }
    
    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<Media Key="$guid" Alias="$filename" Level="2">
  <Info>
    <Parent Key="696c5b71-e2ba-46c3-bb47-106815aa60bc">Жилые Объекты</Parent>
    <Path>/ZhilyeObekty/$filename</Path>
    <Trashed>false</Trashed>
    <ContentType>Image</ContentType>
    <CreateDate>$createDate</CreateDate>
    <NodeName Default="$filename" />
  </Info>
  <Properties>
    <umbracoFile>
      <Value><![CDATA[{
  "src": "/media/$messageId/$filename",
  "focalPoint": null,
  "crops": null
}]]></Value>
    </umbracoFile>
    <umbracoWidth>
      <Value><![CDATA[800]]></Value>
    </umbracoWidth>
    <umbracoHeight>
      <Value><![CDATA[600]]></Value>
    </umbracoHeight>
    <umbracoBytes>
      <Value><![CDATA[$fileSize]]></Value>
    </umbracoBytes>
    <umbracoExtension>
      <Value><![CDATA[$extension]]></Value>
    </umbracoExtension>
  </Properties>
</Media>
"@
    
    return $xml
}

try {
    # 1. Check if source directory exists
    if (-not (Test-Path $sourceDir)) {
        throw "Directory $sourceDir not found!"
    }
    
    # 2. Create output directory
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-Host "Created directory: $outputDir`n" -ForegroundColor Yellow
    }
    
    # 3. Get all image files
    $files = Get-ChildItem -Path $sourceDir -File | Where-Object {
        $_.Extension -match '\.(jpg|jpeg|png|gif|bmp|webp|svg)$'
    }
    
    Write-Host "Found $($files.Count) image files`n" -ForegroundColor Cyan
    
    # 4. Generate mapping and configs
    $mapping = @{}
    $successCount = 0
    $errorCount = 0
    
    foreach ($file in $files) {
        try {
            # Extract Message_ID from filename
            $messageId = "0"
            if ($file.Name -match '^(\d+)_') {
                $messageId = $matches[1]
            }
            
            # Generate input string for GUID
            $guidInput = "media_${messageId}_$($file.Name)"
            
            # DEBUG: Print first 5 to check
            if ($successCount -lt 5) {
                Write-Host "DEBUG: File=$($file.Name), MessageId=$messageId, Input=$guidInput" -ForegroundColor Yellow
            }
            
            # Generate deterministic GUID using BOTH Message_ID and filename
            $guid = Get-DeterministicGuid $guidInput
            
            # Create XML config
            $xml = New-uSyncMediaXml -filename $file.Name -guid $guid -filepath $file.FullName -fileSize $file.Length
            
            # Save XML file (escape wildcards in filename)
            $configPath = Join-Path $outputDir "$($file.Name).config"
            # Use -LiteralPath to handle special characters like [ and ]
            $xml | Out-File -LiteralPath $configPath -Encoding UTF8
            
            # Extract Message_ID from filename
            $messageId = "0"
            if ($file.Name -match '^(\d+)_(.+)$') {
                $messageId = $matches[1]
                $originalName = $matches[2]
            }
            
            # Add to mapping
            if (-not $mapping.ContainsKey($messageId)) {
                $mapping[$messageId] = @{}
            }
            
            $mapping[$messageId][$file.Name] = @{
                guid = $guid
                originalName = $file.Name
                size = $file.Length
                path = "/media/$messageId/$($file.Name)"
            }
            
            $successCount++
            
            if ($successCount % 50 -eq 0) {
                Write-Host "Generated: $successCount configs..." -ForegroundColor Gray
            }
            
        } catch {
            $errorCount++
            Write-Host "Error processing $($file.Name): $_" -ForegroundColor Red
        }
    }
    
    # 5. Save mapping file
    $mapping | ConvertTo-Json -Depth 10 | Out-File $mappingFile -Encoding UTF8
    
    # 6. Final statistics
    Write-Host "`n$('=' * 50)" -ForegroundColor White
    Write-Host "FINAL STATISTICS:" -ForegroundColor Yellow
    Write-Host "$('=' * 50)" -ForegroundColor White
    Write-Host "Successfully generated: $successCount configs" -ForegroundColor Green
    Write-Host "Errors: $errorCount" -ForegroundColor Red
    Write-Host "Total files processed: $($files.Count)" -ForegroundColor Cyan
    Write-Host "$('=' * 50)" -ForegroundColor White
    
    Write-Host "`nMapping saved: $mappingFile" -ForegroundColor Cyan
    Write-Host "Configs saved in: $outputDir" -ForegroundColor Cyan
    
    # 7. Show examples
    Write-Host "`nExample configs:" -ForegroundColor Cyan
    Get-ChildItem $outputDir -Filter "*.config" | Select-Object -First 3 | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }
    
    Write-Host "`nDone!" -ForegroundColor Green
    
} catch {
    Write-Host "`nCritical error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")