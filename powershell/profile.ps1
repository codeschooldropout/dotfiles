Import-Module Terminal-Icons

Set-Alias -Name vi -Value code -Description "Visual Studio Code"
Set-Alias -Name dev -Value Set-DevLocation -Description "Set Dev Location"
Function Set-DevLocation { Set-Location "$env:OneDrive\Dev" }
Function Open-GoPort { Param($Port) New-NetFirewallRule -DisplayName "GoTestingPort$Port" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow } 
Function Close-GoPort { Param($Port) Remove-NetFirewallRule -DisplayName "GoTestingPort$Port" }
Function Show-GoPort {  Get-NetFirewallRule -DisplayName "GoTestingPort*" | Format-Table -Property DisplayName,Enabled,Profiles,Direction,Action }

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