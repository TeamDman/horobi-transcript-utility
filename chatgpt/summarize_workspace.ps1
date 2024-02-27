Write-Host "Creating output dir if not exists"
New-Item -ItemType Directory -Path "outputs" -ErrorAction SilentlyContinue

Write-Host "Clearing previous prompt file"
$outfile = "outputs\prompt.md"
Clear-Content $outfile -ErrorAction SilentlyContinue

Write-Host "Gathering"
# Capture both .ps1 files and the directory structure
$found = Get-ChildItem -Recurse | Where-Object { $_.Name.EndsWith(".ps1") }
Add-Content $outfile "Found $($found.Count) PowerShell scripts in $(Get-Location)`n"

Write-Host "Iterating"
foreach ($file in $found) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
    
    Write-Host "building prompt for $($file.Name)"
    # Use the relative path for the language specifier in markdown code blocks
    Add-Content $outfile "=====BEGIN $relativePath`n$(Get-Content $file -Raw)`n===== END $relativePath"
}

Write-Host "Summary complete. Markdown file created at $outfile"
Get-Content $outfile