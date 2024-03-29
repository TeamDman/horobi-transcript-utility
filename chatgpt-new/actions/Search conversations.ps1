# Get search query from user
$query = fzf --prompt "Enter search query: "

# Search conversations using ripgrep
$results = rg $query "conversations" --column --line-number --no-heading --color=always --smart-case

# Display results with fzf
$results | fzf --ansi --preview 'bat --color=always {1} --highlight-line {2}' --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'