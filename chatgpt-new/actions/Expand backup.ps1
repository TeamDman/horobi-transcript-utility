# Identify the newest backup zip file
$latest_backup = Join-Path `
  -Path ([System.Environment]::GetFolderPath('MyDocuments')) `
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
  if ($entry.FullName -ne "conversations.json") {
    continue
  }
  Write-Host "Found conversations.json in $latest_backup"
  $reader = New-Object System.IO.StreamReader($entry.Open())
  $content = $reader.ReadToEnd()
  $reader.Close()
  break
}
$zip.Dispose()

if (-not $content) {
  Write-Warning "No conversations.json found in $latest_backup"
  return
}

Write-Host "Processing $($content.Length) bytes of conversations.json"
$content `
| ConvertFrom-Json -Depth 100 `
| ForEach-Object -ThrottleLimit 12 -Parallel {
  # Parse the created date
  $date = [datetime]::UnixEpoch.AddSeconds($_.create_time)

  # Build the path
  $date_str = $date.ToString("yyyy/MM/dd")
  $path = "ignore\conversations\$date_str\$($_.id).json"
  
  # Ensure folder exists
  $parent_path = Split-Path -Path $path -Parent
  New-Item -ItemType Directory -Path $parent_path -ErrorAction SilentlyContinue -Force | Out-Null
  
  # Save the conversation
  $_ | ConvertTo-Json -Depth 100 | Set-Content -Path $path
}