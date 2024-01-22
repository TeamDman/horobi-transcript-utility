. .\get_latest_backup.ps1
$found = Get-Backup

Write-Host "Found latest ChatGPT export from $($found.Date)"
Write-Host "Ensuring file is locally available"
if ($(attrib $found.FullName).split() -contains "O") {
    Write-Host "File is not on disk! Downloading..."
    attrib +p $found.FullName
    Start-Sleep -Seconds 10
    attrib -p $found.FullName
} else {
    Write-Host "File is already on disk! Woohoo!"
}