# Find-MediaFiles.ps1
# Scans D:\ for all image and movie files, outputs name & path to a text file

$OutputFile = "C:\Claude\MediaFiles_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

$ImageExtensions = @('*.jpg','*.jpeg','*.png','*.gif','*.bmp','*.tiff','*.tif','*.webp','*.heic','*.heif','*.raw','*.cr2','*.nef','*.arw','*.svg','*.ico')
$VideoExtensions  = @('*.mp4','*.mkv','*.avi','*.mov','*.wmv','*.flv','*.webm','*.m4v','*.mpg','*.mpeg','*.3gp','*.ts','*.mts','*.m2ts','*.vob','*.rmvb','*.divx')

$AllExtensions = $ImageExtensions + $VideoExtensions

Write-Host "Scanning D:\ for images and videos..." -ForegroundColor Cyan

$Results = Get-ChildItem -Path 'D:\' -Recurse -Include $AllExtensions -ErrorAction SilentlyContinue |
    Select-Object Name, FullName

Write-Host "Found $($Results.Count) files. Writing to: $OutputFile" -ForegroundColor Green

# Header
"Media File Scan — D:\" | Out-File -FilePath $OutputFile -Encoding UTF8
"Generated: $(Get-Date)"   | Out-File -FilePath $OutputFile -Encoding UTF8 -Append
"Total Files: $($Results.Count)" | Out-File -FilePath $OutputFile -Encoding UTF8 -Append
("-" * 80)                 | Out-File -FilePath $OutputFile -Encoding UTF8 -Append

# File list
$Results | ForEach-Object {
    "{0,-60} {1}" -f $_.Name, $_.FullName
} | Out-File -FilePath $OutputFile -Encoding UTF8 -Append

Write-Host "Done. Output saved to: $OutputFile" -ForegroundColor Green
