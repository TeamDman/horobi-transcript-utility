# Identify the newest backup zip file
$latest_backup = Join-Path `
  -Path [System.Environment]::GetFolderPath('MyDocuments') `
  -ChildPath "Backups\openai" `
| Get-ChildItem -Filter "*.zip" `
| Sort-Object -Descending -Property {
  $date = $_.Name -replace '.*-(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})\.zip', '$1'
  $date = [datetime]::ParseExact($date, "yyyy-MM-dd-HH-mm-ss", $null)
  $date
} `
| Select-Object -First 1

# Ensure file is downloaded locally
if ($(attrib $latest_backup.FullName).split() -contains "O") {
  Write-Host "Downloading $latest_backup..."
  attrib +p $latest_backup.FullName
  Start-Sleep -Seconds 10
  attrib -p $latest_backup.FullName
}

# Extract conversations
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($latest_backup.FullName)
foreach ($entry in $zip.Entries) {
  $targetPath = Join-Path "conversations" -ChildPath $entry.Name
  $targetDir = Split-Path $targetPath -Parent
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  $entry.ExtractToDirectory($targetPath)
}
$zip.Dispose()

Write-Host "Conversations extracted to 'conversations' folder."