# ensure output dir exists
New-Item -ItemType Directory -Path .\outputs\conversations -ErrorAction SilentlyContinue | Out-Null

# get bearer token
$code = Get-Content inputs\input.txt
$auth = $code | Select-String -Pattern 'authorization' | Select-Object -First 1
$auth = $auth -replace '.*"(.*)".*', '$1'

$conversation_ids = Get-Content .\outputs\conversation-ids-to-download.txt
$i = 0
foreach ($id in $conversation_ids) {
    $i++
    Write-Progress -Activity "Downloading conversations" -Status "Conversation $i of $($conversation_ids.Count)" -PercentComplete ($i / $conversation_ids.Count * 100)
    if (Test-Path ".\outputs\conversations\$id.json") {
        Write-Host "Conversation $id already downloaded"
        continue
    }
    Write-Host "Downloading conversation $id"

    $rand = Get-Random -Minimum 1 -Maximum 5
    Start-Sleep -Seconds $rand

    $uri = "https://chat.openai.com/backend-api/conversation/$id"
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
    $data | ConvertTo-Json -Depth 100 | Out-File -FilePath ".\outputs\conversations\$id.json"
}
