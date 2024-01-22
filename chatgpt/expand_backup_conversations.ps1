$convos = Get-Content .\outputs\backup-conversations.json | ConvertFrom-Json
New-Item -ItemType Directory -Path .\outputs\conversations -ErrorAction SilentlyContinue | Out-Null
$i = 0
foreach ($convo in $convos) {
    # progress bar
    $i++
    Write-Progress -Activity "Expanding conversations" -Status "Conversations expanded: $i" -PercentComplete (($i / $convos.Count) * 100)
    $convo_id = $convo.id
    $convo | ConvertTo-Json -Depth 100 | Out-File -FilePath ".\outputs\conversations\$convo_id.json"
}
