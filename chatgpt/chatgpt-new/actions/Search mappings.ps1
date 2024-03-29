Push-Location .\ignore\conversations
$old = $env:SHELL
$env:SHELL="pwsh"
try {
    $rg_prefix = "rg --column --line-number --no-heading --color=always --smart-case "
    fzf `
        --ansi `
        --disabled `
        --bind "start:reload:$rg_prefix {q}" `
        --bind "change:reload:Start-Sleep 0.1; $rg_prefix {q} || 'not found'" `
        --bind "alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query" `
        --color "hl:-1:underline,hl+:-1:underline:reverse" `
        --prompt '1. ripgrep> ' `
        --delimiter : `
        --preview 'bat --color=always {1} --highlight-line {2}' `
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
}
finally {
    Pop-Location
    $env:SHELL=$old
}