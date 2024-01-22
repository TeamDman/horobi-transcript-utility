function Get-Backup() {
    # Get the path to the current user's Documents folder
    $documentsPath = [System.Environment]::GetFolderPath('MyDocuments')

    # Construct the backup path
    $backup = Join-Path $documentsPath -ChildPath "Backups\openai"

    # ❯ ls $backup  
    # f7e3523a860037df03f4159667310c78871d35b9fbd3ee38766f4077efa38218-2023-11-07-04-19-49.zip
    # 'openai chatgpt download f7e3523a860037df03f4159667310c78871d35b9fbd3ee38766f4077efa38218-2023-08-11-00-12-56.zip'
    $found = Get-ChildItem $backup
    # get the latest according to the date at the end
    # we need to extract the date from the filename
    $found = $found | ForEach-Object { 
        $date = $_.Name -replace '.*-(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})\.zip', '$1'
        $date = [datetime]::ParseExact($date, "yyyy-MM-dd-HH-mm-ss", $null)
        $_ | Add-Member -NotePropertyName "Date" -NotePropertyValue $date -PassThru
    } | Sort-Object -Property Date -Descending | Select-Object -First 1
    return $found
}