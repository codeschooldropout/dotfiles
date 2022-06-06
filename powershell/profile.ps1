Import-Module Terminal-Icons

Set-Alias -Name vi -Value code


if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine

    # Sets up previous command searching using up/down arrows to scroll through previously matching commands and place cursor at the end
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

$themeFile = '~\.oh-my-posh\gruvbot.omp.json'
oh-my-posh --init --shell pwsh --config $themeFile | Invoke-Expression