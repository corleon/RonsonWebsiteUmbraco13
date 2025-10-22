# Configuration
$csvFile = "export20251018193856_clean2.csv"
$mappingFile = "media_mapping_all.json"
$outputDir = "d:\Work\Umbraco\Ronson\Netcat\usync\v9\Contentusync\v9\Content"
$parentKey = "1bca0e81-44d6-46fc-a81c-4a63bbeee5fc" # Zhilye Kompleksy

Write-Host "Starting uSync Content generation...`n" -ForegroundColor Green

# Function to generate deterministic GUID from string
function Get-DeterministicGuid {
    param([string]$inputString)
    
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($inputString))
    $hexString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    
    $guid = $hexString.Substring(0,8) + "-" + 
            $hexString.Substring(8,4) + "-" + 
            $hexString.Substring(12,4) + "-" + 
            $hexString.Substring(16,4) + "-" + 
            $hexString.Substring(20,12)
    
    return $guid
}

# Add this function after Escape-Xml function
function New-DropdownMultipleValue {
    param([string]$text)
    
    if ([string]::IsNullOrEmpty($text) -or $text -eq "NULL") {
        return "[]"
    }
    
    # Split by comma and clean up
    $items = $text -split ',' | ForEach-Object { 
        $_.Trim().ToUpper()  # <-- Добавлен .ToUpper()
    } | Where-Object { 
        -not [string]::IsNullOrWhiteSpace($_) 
    }
    
    if ($items.Count -eq 0) {
        return "[]"
    }
    
    # Build JSON array with proper escaping
    $jsonItems = $items | ForEach-Object {
        $escaped = Escape-Xml $_
        "`"$escaped`""
    }
    
    # Format as multi-line JSON like in the working example
    return "[$([Environment]::NewLine)  " + ($jsonItems -join ",$([Environment]::NewLine)  ") + "$([Environment]::NewLine)]"
}

# Function to create Multiple Media Picker value
function New-MultipleMediaPickerValue {
    param([array]$mediaGuids)
    
    if ($mediaGuids.Count -eq 0) {
        return "[]"
    }
    
    # Build JSON items with unique keys for each
    $items = $mediaGuids | ForEach-Object {
        $uniqueKey = [System.Guid]::NewGuid().ToString()
        "{""key"":""$uniqueKey"",""mediaKey"":""$_""}"
    }
    
    # Single line JSON, no line breaks
    return "[" + ($items -join ",") + "]"
}

# Function to escape XML
function Escape-Xml {
    param([string]$text)
    if ([string]::IsNullOrEmpty($text)) { return "" }
    return $text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")
}

# Function to create Content XML
function New-ContentXml {
    param(
        [string]$guid,
        [string]$alias,
        [string]$nodeName,
        [hashtable]$properties,
        [int]$sortOrder
    )
    
    $createDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    
    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<Content Key="$guid" Alias="$alias" Level="4">
  <Info>
    <Parent Key="$parentKey" />
    <Path>/Glavnaya/Obekty/ZhilyeKompleksy/$alias</Path>
    <Trashed>false</Trashed>
    <ContentType>obEkt</ContentType>
    <CreateDate>$createDate</CreateDate>
    <NodeName Default="$nodeName" />
    <SortOrder>$sortOrder</SortOrder>
    <Published Default="true" />
    <Schedule />
    <Template Key="4e412aa4-a93d-4914-9374-9677188720d2">ObEkt</Template>
  </Info>
  <Properties>
    <objectName>
      <Value><![CDATA[$($properties.objectName)]]></Value>
    </objectName>
    <description>
      <Value><![CDATA[$($properties.description)]]></Value>
    </description>
    <god>
      <Value><![CDATA[$($properties.god)]]></Value>
    </god>
    <imageGallery>
      <Value><![CDATA[$($properties.imageGallery)]]></Value>
    </imageGallery>
    <systems>
      <Value><![CDATA[$($properties.systems)]]></Value>
    </systems>
    <obl>
      <Value><![CDATA[$($properties.obl)]]></Value>
    </obl>
    <montage>
      <Value><![CDATA[$($properties.montage)]]></Value>
    </montage>
    <montagepartner>
      <Value><![CDATA[$($properties.montagepartner)]]></Value>
    </montagepartner>
    <inside>
      <Value><![CDATA[$($properties.inside)]]></Value>
    </inside>
    <ronsonSystem>
      <Value><![CDATA[$($properties.ronsonSystem)]]></Value>
    </ronsonSystem>
    <ronsonMontage>
      <Value><![CDATA[$($properties.ronsonMontage)]]></Value>
    </ronsonMontage>
    <ronsonVitrage>
      <Value><![CDATA[$($properties.ronsonVitrage)]]></Value>
    </ronsonVitrage>
    <ronsonGranit>
      <Value><![CDATA[$($properties.ronsonGranit)]]></Value>
    </ronsonGranit>
    <ronsonKlinker>
      <Value><![CDATA[$($properties.ronsonKlinker)]]></Value>
    </ronsonKlinker>
    <ronsonDecor>
      <Value><![CDATA[$($properties.ronsonDecor)]]></Value>
    </ronsonDecor>
    <ronsonBrick>
      <Value><![CDATA[$($properties.ronsonBrick)]]></Value>
    </ronsonBrick>
    <pageTitle>
      <Value><![CDATA[$($properties.pageTitle)]]></Value>
    </pageTitle>
    <metaDescription>
      <Value><![CDATA[$($properties.metaDescription)]]></Value>
    </metaDescription>
    <metaKeywords>
      <Value><![CDATA[$($properties.metaKeywords)]]></Value>
    </metaKeywords>
    <canonicalUrl>
      <Value><![CDATA[]]></Value>
    </canonicalUrl>
    <hideFromSearch>
      <Value><![CDATA[0]]></Value>
    </hideFromSearch>
    <ogImage>
      <Value><![CDATA[[]]]></Value>
    </ogImage>
    <heroTitle>
      <Value><![CDATA[]]></Value>
    </heroTitle>
    <heroDescription>
      <Value><![CDATA[]]></Value>
    </heroDescription>
    <heroButtonText>
      <Value><![CDATA[]]></Value>
    </heroButtonText>
    <heroButtonUrl>
      <Value><![CDATA[]]></Value>
    </heroButtonUrl>
    <hideHeroSection>
      <Value><![CDATA[0]]></Value>
    </hideHeroSection>
  </Properties>
</Content>
"@
    
    return $xml
}

try {
    # 1. Check files
    if (-not (Test-Path $csvFile)) { throw "CSV file not found: $csvFile" }
    if (-not (Test-Path $mappingFile)) { throw "Mapping file not found: $mappingFile" }
    
    # 2. Load mapping
    Write-Host "Loading media mapping..." -ForegroundColor Cyan
    $mapping = Get-Content $mappingFile -Encoding UTF8 | ConvertFrom-Json
    
    # 3. Load CSV
    Write-Host "Loading CSV data..." -ForegroundColor Cyan
    
    # Try to detect delimiter
    $firstLine = Get-Content $csvFile -First 1 -Encoding UTF8
    $delimiter = if ($firstLine -match ';') { ';' } else { ',' }
    Write-Host "Using delimiter: '$delimiter'" -ForegroundColor Yellow
    
    $csvData = Import-Csv $csvFile -Encoding UTF8 -Delimiter $delimiter
    
    Write-Host "Found $($csvData.Count) objects in CSV`n" -ForegroundColor Green
    
    # 4. Create output directory
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-Host "Created directory: $outputDir`n" -ForegroundColor Yellow
    }
    
    # 5. Process each object
    $successCount = 0
    $errorCount = 0
    $sortOrder = 0
    
    $rowIndex = 2 # Start from 2 (1-based, assuming header is row 1)
    
    foreach ($row in $csvData) {
        try {
            # Extract Message_ID from first gallery image instead of cover
            $messageId = "000000"
            
            # Try to get Message_ID from img1 (first gallery image)
            if ($row.img1 -and $row.img1 -ne "NULL") {
                $firstImgFileName = $row.img1.Split(':')[0]
                # Look for this file in mapping to get Message_ID
                foreach ($msgId in $mapping.PSObject.Properties.Name) {
                    $fullFileName = "${msgId}_${firstImgFileName}"
                    if ($mapping.$msgId.$fullFileName) {
                        $messageId = $msgId
                        break
                    }
                }
            }
            
            # If no img1, use row index as Message_ID
            if ($messageId -eq "000000") {
                $messageId = $rowIndex.ToString().PadLeft(6, '0')
            }
            
            # Generate GUID for content node
            $guid = Get-DeterministicGuid "content_$messageId"
            
            # Create alias (safe URL)
            $alias = "obekt-$messageId"
            
            # Get media GUIDs for gallery
            $galleryGuids = @()
            
            # Gallery images (img1-img20)
            for ($i = 1; $i -le 20; $i++) {
                $imgField = "img$i"
                if ($row.$imgField -and $row.$imgField -ne "NULL") {
                    $imgFileName = $row.$imgField.Split(':')[0]
                    $fullFileName = "${messageId}_${imgFileName}"
                    if ($mapping.$messageId.$fullFileName) {
                        $galleryGuids += $mapping.$messageId.$fullFileName.guid
                    }
                }
            }
            
            # Build properties (removed cover property)
            $properties = @{
                objectName = Escape-Xml $row.name
                description = Escape-Xml $row.description
                god = if ($row.god -and $row.god -ne "NULL") { $row.god } else { "" }
                imageGallery = New-MultipleMediaPickerValue $galleryGuids
                systems = New-DropdownMultipleValue $row.system
                obl = Escape-Xml $row.obl
                montage = Escape-Xml $row.montage
                montagepartner = Escape-Xml $row.montagepartner
                inside = if ($row.inside -eq "1") { "1" } else { "0" }
                ronsonSystem = if ($row.ronson_system -eq "1") { "1" } else { "0" }
                ronsonMontage = if ($row.ronson_montage -eq "1") { "1" } else { "0" }
                ronsonVitrage = if ($row.ronson_vitrage -eq "1") { "1" } else { "0" }
                ronsonGranit = if ($row.ronson_granit -eq "1") { "1" } else { "0" }
                ronsonKlinker = if ($row.ronson_klinker -eq "1") { "1" } else { "0" }
                ronsonDecor = if ($row.ronson_decor -eq "1") { "1" } else { "0" }
                ronsonBrick = if ($row.ronson_brick -eq "1") { "1" } else { "0" }
                pageTitle = Escape-Xml $row.ncTitle
                metaDescription = Escape-Xml $row.ncDescription
                metaKeywords = Escape-Xml $row.ncKeywords
            }
            
            # Create XML
            $xml = New-ContentXml -guid $guid -alias $alias -nodeName $row.name -properties $properties -sortOrder $sortOrder
            
            # Save file with UTF-8 BOM encoding (required for uSync)
            $configPath = Join-Path $outputDir "$alias.config"
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText($configPath, $xml, $utf8WithBom)
            
            $successCount++
            $sortOrder++
            $rowIndex++
            
            if ($successCount % 25 -eq 0) {
                Write-Host "Generated: $successCount configs..." -ForegroundColor Gray
            }
            
        } catch {
            $errorCount++
            $rowIndex++
            Write-Host "Error processing row $rowIndex : $_" -ForegroundColor Red
        }
    }
    
    # 6. Final statistics
    Write-Host "`n$('=' * 50)" -ForegroundColor White
    Write-Host "FINAL STATISTICS:" -ForegroundColor Yellow
    Write-Host "$('=' * 50)" -ForegroundColor White
    Write-Host "Successfully generated: $successCount configs" -ForegroundColor Green
    Write-Host "Errors: $errorCount" -ForegroundColor Red
    Write-Host "Total objects: $($csvData.Count)" -ForegroundColor Cyan
    Write-Host "$('=' * 50)" -ForegroundColor White
    
    Write-Host "`nConfigs saved in: $outputDir" -ForegroundColor Cyan
    Write-Host "`nDone!" -ForegroundColor Green
    
} catch {
    Write-Host "`nCritical error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
