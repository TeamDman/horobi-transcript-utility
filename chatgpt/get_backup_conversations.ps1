. .\get_latest_backup.ps1
$found = Get-Backup

New-Item -ItemType Directory -Path "outputs" -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$zipFilePath = $found.FullName

# Open the zip file
$zipStream = [System.IO.File]::OpenRead($zipFilePath)
$zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream)

# Iterate through each file in the zip
foreach ($entry in $zipArchive.Entries) {
    Write-Host "Entry: $($entry.FullName)"

    # If you want to perform operations on each file, you can open a stream
    # For example, to read the content of a file:
    if (!$entry.FullName.EndsWith("/")) { # This checks if the entry is a file
        if ($entry.FullName -eq "conversations.json") {
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $content = $reader.ReadToEnd()
            # pretty print
            Set-Content -Path "outputs\backup-conversations.json" -Value $($content | ConvertFrom-Json | ConvertTo-Json -Depth 100)
            $reader.Close()
        }
    }
}

# Clean up
$zipArchive.Dispose()
$zipStream.Close()
