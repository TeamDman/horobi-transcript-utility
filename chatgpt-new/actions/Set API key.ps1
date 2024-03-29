# Choose input method
$choice = fzf --prompt "Choose input method: " --header "Set API Key" --options "Clipboard", "Manual"

if ($choice -eq "Clipboard") {
  $apiKey = Get-Clipboard
} else {
  Write-Host -NoNewLine "Enter the API key: "
  $apiKey = Read-Host -MaskInput
}

# Extract bearer token
$bearerToken = $apiKey -replace '.*Bearer (.*)', '$1'

# Set environment variable
$env:CHATGPT_API_KEY = $bearerToken

Write-Host "API Key set as environment variable."