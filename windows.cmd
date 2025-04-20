@echo off
cls
color 07
title Setup
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

powershell.exe "cd %~dp0; $f=[io.file]::ReadAllText('%~f0') -Split ':Programs\:.*'; Set-Content -Path 'programs.json' -Value ($f[1]); winget import -i 'programs.json' --accept-package-agreements --accept-source-agreements; Remove-Item -Recurse $ENV:USERPROFILE\Desktop\*.lnk"
del programs.json

powershell.exe "cd %~dp0; $f=[io.file]::ReadAllText('%~f0') -Split ':Settings\:.*'; Invoke-Expression ($f[1]);" & goto End

:Programs:
{
	"$schema" : "https://aka.ms/winget-packages.schema.2.0.json",
	"CreationDate" : "2025-04-19T23:05:49.447-00:00",
	"Sources" : 
	[
		{
			"Packages" : 
			[
				{
					"PackageIdentifier" : "7zip.7zip"
				},
				{
					"PackageIdentifier" : "Git.Git"
				},
				{
					"PackageIdentifier" : "Microsoft.Office"
				},
				{
					"PackageIdentifier" : "Proton.ProtonVPN"
				},
				{
					"PackageIdentifier" : "Zen-Team.Zen-Browser"
				},
				{
					"PackageIdentifier" : "JanDeDobbeleer.OhMyPosh"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2010.x64"
				},
				{
					"PackageIdentifier" : "OpenJS.NodeJS"
				},
				{
					"PackageIdentifier" : "GitHub.cli"
				},
				{
					"PackageIdentifier" : "Microsoft.PowerShell"
				},
				{
					"PackageIdentifier" : "OBSProject.OBSStudio"
				},
				{
					"PackageIdentifier" : "Valve.Steam"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2013.x64"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2012.x86"
				},
				{
					"PackageIdentifier" : "Microsoft.DotNet.DesktopRuntime.8"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2013.x86"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2010.x86"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2015+.x86"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2015+.x64"
				},
				{
					"PackageIdentifier" : "Microsoft.VCRedist.2012.x64"
				},
				{
					"PackageIdentifier" : "Notion.Notion"
				},
				{
					"PackageIdentifier" : "Discord.Discord"
				},
				{
					"PackageIdentifier" : "Postman.Postman"
				},
				{
					"PackageIdentifier" : "Notion.NotionCalendar"
				},
				{
					"PackageIdentifier" : "Python.Python.3.13"
				},
				{
					"PackageIdentifier" : "Anysphere.Cursor"
				},
				{
					"PackageIdentifier" : "Microsoft.PowerToys"
				},
				{
					"PackageIdentifier" : "Microsoft.AppInstaller"
				},
				{
					"PackageIdentifier" : "Microsoft.UI.Xaml.2.8"
				},
				{
					"PackageIdentifier" : "Microsoft.VCLibs.Desktop.14"
				},
				{
					"PackageIdentifier" : "Microsoft.WindowsTerminal"
				},
				{
					"PackageIdentifier" : "Microsoft.WSL"
				},
				{
					"PackageIdentifier" : "Gyan.FFmpeg"
				}
			],
			"SourceDetails" : 
			{
				"Argument" : "https://cdn.winget.microsoft.com/cache",
				"Identifier" : "Microsoft.Winget.Source_8wekyb3d8bbwe",
				"Name" : "winget",
				"Type" : "Microsoft.PreIndexed.Package"
			}
		},
		{
			"Packages" : 
			[
				{
					"PackageIdentifier" : "9NT1R1C2HH7J"
				}
			],
			"SourceDetails" : 
			{
				"Argument" : "https://storeedgefd.dsx.mp.microsoft.com/v9.0",
				"Identifier" : "StoreEdgeFD",
				"Name" : "msstore",
				"Type" : "Microsoft.Rest"
			}
		}
	],
	"WinGetVersion" : "1.10.340"
}
:Programs:

:Settings:
# File Explorer
Write-Output "Enabling developer-specific settings..."

# Allow running local PowerShell scripts without signing (only for local scripts)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Registry path for Explorer settings
$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Show hidden files and folders
Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1

# Show system files (and hide the warning)
Set-ItemProperty -Path $explorerPath -Name "ShowSuperHidden" -Value 1

# Show file name extensions
Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0

Write-Output "✅ Developer settings enabled successfully."

# Python
$libraries = @(
	"numpy",
	"pandas",
	"yt-dlp"
)

foreach ($library in $libraries) {
	pip install $library
}

# Windows Terminal
# Font
oh-my-posh.exe font install CascadiaCode
$settingsPath = Resolve-Path "$ENV:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json"
$settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
$font = "CaskaydiaCove NF"
$settings.profiles.defaults = @{}
$settings.profiles.defaults.font = @{
    face = $font
}
$settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath

# PowerShell Profile
New-Item -Type File -Path $PROFILE -Force
Add-Content -Path $PROFILE -Value "oh-my-posh init pwsh | Invoke-Expression"

# PowerShell 7 Profile
$profile7 = "$ENV:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
New-Item -Type File -Path $profile7 -Force
Add-Content -Path $profile7 -Value "oh-my-posh init pwsh | Invoke-Expression"

# Default WSL Profile
$wslProfile = $settings.profiles.list | Where-Object { $_.name -eq "Ubuntu" }
$settings.defaultProfile = $wslProfile.guid
$settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath
:Settings:

:End
del "%~f0"
