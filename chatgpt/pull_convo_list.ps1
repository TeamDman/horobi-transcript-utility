$backup = Get-Content .\outputs\backup-conversations.json | ConvertFrom-Json
# Create a DateTime object for the Unix epoch
$epoch = [datetime]'1970-01-01T00:00:00Z'
# Add the number of seconds in the Unix timestamp to the epoch
$backup_date = $epoch.AddSeconds($($backup.update_time | Sort-Object -Bottom 1))

Write-Host "Latest update in the backup: $backup_date"

$code = Get-Content inputs\input.txt
# Extract `"authorization"="Bearer ..."` from the code file
$auth = $code | Select-String -Pattern 'authorization' | Select-Object -First 1
# now we have `"authorization" = "Bearer ..."` so we want the string inside the second quote pair
$auth = $auth -replace '.*"(.*)".*', '$1'

$uri = "https://chat.openai.com/backend-api/conversations?offset=0&limit=100&order=updated"
$headers = @{
  "authority"="chat.openai.com"
  "authorization" = "$auth"
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"

$resp = Invoke-WebRequest `
-UseBasicParsing `
-WebSession $session `
-Uri $uri `
-Headers $headers

$data = $resp.Content | ConvertFrom-Json
Write-Host "Fetched $($data.items.Count) items out of $($data.total)"
$fetched_date = $data.items.update_time | Sort-Object -Top 1
Write-Host "Oldest update: $($fetched_date)"

$results = @()

# If the oldest update is still newer than the backup, we need to fetch more
if ($fetched_date -gt $backup_date) {
  $offset = 100
  while ($fetched_date -gt $backup_date) {
    Start-Sleep -Seconds 3
    $results += $data.items
    $uri = "https://chat.openai.com/backend-api/conversations?offset=$offset&limit=100&order=updated"
    $resp = Invoke-WebRequest `
    -UseBasicParsing `
    -WebSession $session `
    -Uri $uri `
    -Headers $headers
    $data = $resp.Content | ConvertFrom-Json
    Write-Host "Received $($data.items.Count) items, apparently $($data.total) exist remotely. Total received: $($results.Count)"
    $fetched_date = $data.items.update_time | Sort-Object -Top 1
    Write-Host "Oldest update: $($fetched_date)"
    $offset += 100
  }
  $results += $data.items
} else {
  $results = $data.items
}

Write-Host "Total fetched items: $($results.Count)"
Set-Content -Path .\outputs\conversations.json -Value ($results | ConvertTo-Json -Depth 100)
