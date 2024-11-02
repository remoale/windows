@echo off
cls
color 07
title Winget
mode 76, 30
set "nul1=1>nul"
set "nul2=2>nul"

::  Disable QuickEdit for this cmd.exe session only

reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% || if not defined quedit (
	reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "0" /f %nul1%
	start cmd.exe /c "%~f0"
	exit /b
)

::  Elevate script as admin

%nul1% fltmc || (
	powershell.exe "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs" && exit /b
	echo: &echo ==== ERROR ==== &echo:
	echo This script requires admin privileges.
	echo Press any key to exit...
	pause >nul
	exit
)

powershell.exe "cd %~dp0; $f=[io.file]::ReadAllText('%~f0') -Split ':Install\:.*'; Invoke-Expression ($f[1]);" & goto End

:Install:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$programs = [ordered]@{
	"Bitwarden" = "Bitwarden";
	"Microsoft" = @(
		"Edge",
		"WindowsTerminal",
		"VisualStudioCode",
		"PowerShell",
		"DevHome",
		"Office",
		"OneDrive",
		"PCManager",
		"PowerToys",
		"Sysinternals"
	);
	"Notion" = @(
		"Notion",
		"NotionCalendar"
	);
	"" = @(
		"9PKTQ5699M62",
		"9PFHDD62MXS1"
	);
	"Python" = "Python.3.12";
	"JanDeDobbeleer" = "OhMyPosh";
	"Git" = "Git";
	"GitHub" = "GitHubDesktop";
	"Neovim" = "Neovim";
	"Gyan" = "FFmpeg";
	"Discord" = "Discord"
}

foreach ($key in $programs.Keys) {
	foreach ($value in $programs[$key]) {
		if ($key) {
			winget install "$key.$value" --accept-package-agreements --accept-source-agreements
		} else {
			winget install "$value" --accept-package-agreements --accept-source-agreements
		}
	}
}

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install -y mingw make

# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module.
# Note: Using `. $PROFILE` instead *may* work, but isn't guaranteed to.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# refreshenv is now an alias for Update-SessionEnvironment
# (rather than invoking refreshenv.cmd, the *batch file* for use with cmd.exe)
# This should make git.exe accessible via the refreshed $env:PATH, so that it
# can be called by name only.
refreshenv

$libraries = @(
	"numpy",
	"pandas",
	"yt-dlp"
)

foreach ($library in $libraries) {
	pip install $library
}

oh-my-posh.exe font install CascadiaCode

$settingsPath = Resolve-Path "$ENV:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json"
$settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
$pwsh7Profile = $settings.profiles.list | Where-Object { $_.name -eq "PowerShell" }
$settings.defaultProfile = $pwsh7Profile.guid
$font = "CaskaydiaCove NF"
$settings.profiles.defaults = @{}
$settings.profiles.defaults.font = @{
    face = $font
}
$settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath
New-Item -Type File -Path $PROFILE -Force
Add-Content -Path $PROFILE -Value "oh-my-posh init pwsh | Invoke-Expression"
$profile7 = "$ENV:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
New-Item -Type File -Path $profile7 -Force
Add-Content -Path $profile7 -Value "oh-my-posh init pwsh | Invoke-Expression"

git clone https://github.com/NvChad/starter $ENV:USERPROFILE\AppData\Local\nvim; nvim

Remove-Item "$ENV:USERPROFILE\Desktop\GitHub Desktop.lnk" -Force
Remove-Item "$ENV:USERPROFILE\Desktop\Discord.lnk" -Force

wsl --install
:Install:

:End
del "%~f0"