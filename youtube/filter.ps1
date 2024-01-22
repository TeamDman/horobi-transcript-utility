$z = Get-Content related_history_grabber\target\youtube_watch_history.json | ConvertFrom-Json
$z | Where-Object { $_.video_title -like "*comedy*" } | code -