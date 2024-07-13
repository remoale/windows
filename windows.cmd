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
Install-PackageProvider -Name "NuGet" -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Script winget-install -Force
Set-ExecutionPolicy Unrestricted
winget-install -Force

$programs = [ordered]@{
	"Microsoft" = @(
		"DevHome",
		"PCManager",
		"Office",
		"OneDrive",
		"VisualStudioCode",
		"PowerShell",
		"WindowsTerminal"
	);
	"Notion" = @(
		"Notion",
		"NotionCalendar"
	);
	"Adobe" = "CreativeCloud";
	"Python" = "Python.3.12";
	"JanDeDobbeleer" = "OhMyPosh";
	"MSYS2" = "MSYS2";
	"Git" = "Git";
	"GitHub" = "GitHubDesktop";
	"Neovim" = "Neovim";
	"Discord" = "Discord"
}

foreach ($key in $programs.Keys) {
	foreach ($value in $programs[$key]) {
		winget install "$key.$value" --accept-package-agreements --accept-source-agreements
	}
}

Remove-Item "$ENV:USERPROFILE\Desktop\Notion.lnk" -Force
Remove-Item "$ENV:USERPROFILE\Desktop\Notion Calendar.lnk" -Force
Remove-Item "$ENV:USERPROFILE\Desktop\Discord.lnk" -Force

. $PROFILE
. ("$ENV:USERPROFILE\AppData\Local\Programs\oh-my-posh\bin\oh-my-posh.exe") font install CascadiaCode

$settingsPath = Resolve-Path "$ENV:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json"
$settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
$font = "CaskaydiaCove Nerd Font"
$settings.profiles.defaults = @{}
$settings.profiles.defaults.font = @{
    face = $font
}
$settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath
New-Item -Type File -Path $PROFILE -Force
Add-Content -Path $PROFILE -Value "oh-my-posh init pwsh | Invoke-Expression"
"@
:Install:

:End
pause >nul
del "%~f0"