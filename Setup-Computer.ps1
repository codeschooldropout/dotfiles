# ---------------------------------------------------------------------------- #
#                                   Functions                                  #
# ---------------------------------------------------------------------------- #
Function Install-NerdFont($Font)  {
    # this installs fonts into user space compared to Install-Font.ps1 which is admin, though supposely it falls back.
    # This also is not silent, unavoidable unless manually done without the special path things.
    # http://www.edugeek.net/forums/windows-7/123187-installation-fonts-without-admin-rights-2.html

    $githubFont = "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    $githubFontUris = ((Invoke-WebRequest $githubFont) | ConvertFrom-Json).assets.browser_download_url
    $githubFontUri = (@($githubFontUris) -match $Font) | Out-String
    Invoke-WebRequest -Uri $githubFontUri -Outfile $env:temp\font.zip
    Expand-Archive $env:temp\font.zip -DestinationPath $env:temp\font\ -Force

    $fontPath = (New-Object -ComObject Shell.Application).Namespace(0x14)

    Get-ChildItem -Path $env:temp\font\ -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach-Object {
        If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
            $fontPath.CopyHere($_.FullName,0x10) 
        }
        
    }
}


Function Set-Registry( $RegistryPath, $Name, $Value ) {
    # Create the key if it does not exist
    If (-NOT (Test-Path $RegistryPath)) {
      New-Item -Path $RegistryPath -Force | Out-Null
    }  
    # Now set the value
    New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force
}


# Run commands in user space as required before self-elevatating to complete steps
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {

    # Download and install the latest version of the Font
    Install-NerdFont "CascadiaCode"

    # Set Timezone
    Set-Timezone "Eastern Standard Time"

    # Install Spotify
    winget install -e --id Spotify.Spotify

    # BUG - This will try to launch pwsh w/o checking if its installed It also will be responsible for installing pwsh7 so this is broken on a new system and needs rework
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath pwsh.exe -Verb Runas -ArgumentList $CommandLine
    Exit
 }
}
# TODO - figure out what context this needs to run in
# TODO - the esclation code runs in the default powershell but some of this needs to be done in powershell7, namely the configuration for ps7.

# Get path of repo to create symlinks to
$RepoPath = Split-Path $MyInvocation.MyCommand.Path -Parent

# Create symlinks to the repo config files
New-Item -ItemType SymbolicLink -Target "$RepoPath\oh-my-posh\gruvbot.omp.json" -Path "~\.oh-my-posh\gruvbot.omp.json" -Force
New-Item -ItemType SymbolicLink -Target "$RepoPath\powershell\profile.ps1" -Path $PROFILE.CurrentUserAllHosts -Force
New-Item -ItemType SymbolicLink -Target "$RepoPath\powershell\gruvbot-colors.psd1" -Path "$(Split-Path $PROFILE.CurrentUserAllHosts -Parent)\gruvbot-colors.psd1" -Force
New-Item -ItemType SymbolicLink -Target "$RepoPath\powershell\gruvbot-icons.psd1" -Path "$(Split-Path $PROFILE.CurrentUserAllHosts -Parent)\gruvbot-icons.psd1" -Force
New-Item -ItemType SymbolicLink -Target "$RepoPath\windows-terminal\settings.json" -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json" -Force

# TODO - Setup Terminal-Icons theme and icons

# Copy icon images for use in Windows Terminal menus
Copy-Item -Path "$RepoPath\windows-terminal\icons\*" -Destination "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\RoamingState" -Force

# ---------------------------------------------------------------------------- #
#                               Registry Changes                               #
# ---------------------------------------------------------------------------- #
# Set variables to indicate value and key to set 
# TODO Convert these to @{@{}}

# Enables the "Autohide Taskbar" feature in Explorer this changes a value inside binary blob of the registry
$RegistryPath = 'HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
$Name         = 'Settings'
$Value        = '3'

$v=(Get-ItemProperty -Path $RegistryPath).Settings
$v[8]=$Value;
Set-ItemProperty -Path $RegistryPath -Name Settings -Value $v

# Remove items from Windows 11 taskbar
# Remove Chat
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "TaskbarMn"
$Value = 0
Set-Registry $RegistryPath $Name $Value

# Remove Search
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$Name = "SearchboxTaskbarMode"
$Value = 0
Set-Registry $RegistryPath $Name $Value

# Enables Dark mode in Windows 10
$RegistryPath = 'HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$Name         = 'AppsUseLightTheme'
$Value        = '0'
Set-Registry $RegistryPath $Name $Value

$Name         = 'SystemUsesLightTheme'
$Value        = '0'
Set-Registry $RegistryPath $Name $Value

# ColorPrevalence:
# 1 = Show color on Start, taskbar, and action center
# 2 = Show color only on taskbar
$Name         = 'ColorPrevalence'
$Value        = '1'
Set-Registry $RegistryPath $Name $Value

$name         = 'EnableTransparency'
$value        = '1'
Set-Registry $RegistryPath $Name $Value

# Enables the ability to color taskbar instead of just white
$RegistryPath = 'HKCU:SOFTWARE\Microsoft\Windows\DWM'
$Name         = 'EnableWindowColorization'
$Value        = '1'
Set-Registry $RegistryPath $Name $Value

# ColorPrevalence:
# 1 = Show color on Start, taskbar, and action center
# 2 = Show color only on taskbar
$Name         = 'ColorPrevalence'
$Value        = '1'
Set-Registry $RegistryPath $Name $Value

# Hide Desktop Icons
$RegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$Name         = 'HideIcons'
$Value        = '1'
Set-Registry $RegistryPath $Name $Value

# Automatically select accent colors
$RegistryPath = 'HKCU:\Control Panel\Desktop'
$Name        = 'AutoColorization'
$Value       = '1'
Set-Registry $RegistryPath $Name $Value
# ---------------------------------------------------------------------------- #
#                             Install Applications                             #
# ---------------------------------------------------------------------------- #

# Utilities
winget install -e --id Microsoft.WindowsTerminal.Preview
winget install -e --id Microsoft.PowerToys
winget install -e --id Microsoft.RemoteDesktopClient
winget install -e --id 7zip.7zip
winget install -e --id ShareX.ShareX
winget install -e --id Bitwarden.Bitwarden
winget install -e --id Ditto.Ditto

# Talkies
winget install -e --id Discord.Discord

# Images
winget install -e --id IrfanSkiljan.IrfanView
winget install -e --id Gimp.Gimp
winget install -e --id Inkscape.Inkscape

# Browsers
winget install -e --id Google.Chrome
winget install -e --id Mozilla.Firefox
winget install -e --id BraveSoftware.BraveBrowser

# Media Players
winget install -e --id VideoLAN.VLC

# Writey Ready Stuff
winget install -e --id AcroSoftware.CutePDFWriter
winget install -e --id Obsidian.Obsidian
winget install -e --id Microsoft.Office

# Network Utilities
winget install -e --id Famatech.AdvancedIPScanner
winget install -e --id OpenVPNTechnologies.OpenVPNConnect

# Development Tools
winget install -e --id Git.Git
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Microsoft.PowerShell
winget install -e --id JanDeDobbeleer.OhMyPosh
winget install -e --id Docker.DockerDesktop
winget install -e --id Python.Python.3
winget install -e --id GoLang.Go
winget install -e --id Microsoft.AzureCLI

# Drives and Hardware
winget install -e --id Logitech.GHUB
winget install -e --id Logitech.OptionsPlus

# ---------------------------------------------------------------------------- #
#                    Changes made only to my current laptop                    #
# ---------------------------------------------------------------------------- #

if ($(Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Expand Model) -eq 'ROG Zephyrus G14 GA401QM') {

  # Setup power management for the Asus Zephyrus G14 2021 
  # https://www.asus.com/us/Motherboards/Zephyrus_G14_2021/
  # Enable Processor Performance Boost Mode
  $RegistryPath = 'HKLM:SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
  $Name         = 'Attributes'
  $Value        = '2'
  Set-Registry $RegistryPath $Name $Value
  

  # TODO These keys appear to change every time it recreates the power plans or on a new system, possible to check for an existing folder and change it next reinstall?

  # Disable Boost Mode for all four power profiles
  # $RegistryPath = 'HKLM:\System\ControlSet001\Control\Power\PowerSettings\6fecc5ae-f350-48a5-b669-b472cb895ccf\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7]'
  # $Name         = 'ACSettingIndex'
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $Name         = 'DCSettingIndex' 
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $RegistryPath = 'HKLM:\System\ControlSet001\Control\Power\PowerSettings\64a64f24-65b9-4b56-befd-5ec1eaced9b3\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7]'
  # $Name         = 'ACSettingIndex'
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $Name         = 'DCSettingIndex' 
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $RegistryPath = 'HKLM:\System\ControlSet001\Control\Power\PowerSettings\381b4222-f694-41f0-9685-ff5bb260df2e\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
  # $Name         = 'ACSettingIndex'
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $Name         = 'DCSettingIndex' 
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $RegistryPath = 'HKLM:\System\ControlSet001\Control\Power\PowerSettings\27fa6203-3987-4dcc-918d-748559d549ec\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7]'
  # $Name         = 'ACSettingIndex'
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

  # $Name         = 'DCSettingIndex' 
  # $Value        = '0'
  # Set-Registry $RegistryPath $Name $Value

}

# ---------------------------------------------------------------------------- #
#                                 Finishing Up                                 #
# ---------------------------------------------------------------------------- #

# Setup gitconfig
# Might be required for installs that use git. So this might be wrong section. Also will need same things for linux systems 
# Find way to reuse this between powershell/bash (dont use powershell to setup linux even if that is funny to you) 
git config --global init.defaultBranch main
git config --global user.name "codeschooldropout"
git config --global user.email "codeschooldropout@users.noreply.github.com"
git config --global user "codeschooldropout"

# Set the sshd service to be started automatically and start it
Get-Service ssh-agent | Set-Service -StartupType Automatic | Start-Service

# Restart Windows Explorer
Stop-Process -ProcessName explorer -Force

# Tell git to use windows ssh and ssh-agent
[Environment]::SetEnvironmentVariable("GIT_SSH", "$((Get-Command ssh).Source)", [System.EnvironmentVariableTarget]::User)

Read-Host "Done!"