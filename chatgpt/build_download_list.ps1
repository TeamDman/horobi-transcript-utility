# Read the contents of backup-conversations.json and conversations.json
$backupConversations = Get-Content -Raw -Path "outputs\backup-conversations.json" | ConvertFrom-Json
$conversations = Get-Content -Raw -Path "outputs\conversations.json" | ConvertFrom-Json

# Create a hashtable to store the backup conversations by ID
$backupConversationsById = @{}
$epoch = [datetime]'1970-01-01T00:00:00Z'
foreach ($conversation in $backupConversations) {
    $backupConversationsById[$conversation.id] = $epoch.AddSeconds($($backup.update_time | Sort-Object -Bottom 1))
}

# Filter conversations from conversations.json based on update_time
$newConversations = $conversations | Where-Object {
    if ($backupConversationsById.ContainsKey($_.id)) {
        return [DateTime]::Parse($_.update_time) -gt $backupConversationsById[$_.id]
    }
    else {
        return $true
    }
}

# Get the IDs of conversations from conversations.json with newer update_time
$newConversationIds = $newConversations | Sort-Object -Property update_time -Descending | Select-Object -ExpandProperty id

# Output the conversation IDs
$newConversationIds > outputs\conversation-ids-to-download.txt
