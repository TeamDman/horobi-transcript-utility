$videos = Get-Content related_history_grabber\target\youtube_watch_history.json | ConvertFrom-Json

# Hashtable to keep track of seen video URLs
$uniqueVideos = @{}

$videos | ForEach-Object {
    # Use video_url as the unique key
    if (-not $uniqueVideos.ContainsKey($_.video_url)) {
        # Add to the hashtable if it's a new URL
        $uniqueVideos[$_.video_url] = $true

        # Output the formatted string for unique videos only
        "$($_.watch_time)`t$($_.channel_name)`t$($_.video_title)`t$($_.video_url)`t$($_.channel_url)"
    }
} | fzf

# $z | Where-Object { $_.video_title -like "*comedy*" } | code -
#$z | % { "$($_.video_title) $($_.url) }