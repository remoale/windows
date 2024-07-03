@echo off
cls
color 07
title Winget
mode 76, 30
set "nul1=1>nul"
set "nul2=2>nul"

::  Elevate script as admin

%nul1% fltmc || (
	powershell.exe "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs" && exit /b
	echo: &echo ==== ERROR ==== &echo:
	echo This script requires admin privileges.
	echo Press any key to exit...
	pause >nul
	exit
)

::  Disable QuickEdit for this cmd.exe session only

reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% || if not defined quedit (
	reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "0" /f %nul1%
	start cmd.exe /c "%~f0"
	exit /b
)

powershell.exe "cd %~dp0; $f=[io.file]::ReadAllText('%~f0') -Split ':Install\:.*'; Invoke-Expression ($f[1]);" & goto End

:Install:
start ms-windows-store:
cd ~\Downloads
Start-BitsTransfer -Source "https://cdn.winget.microsoft.com/cache/source.msix"
Start-Process ~\Downloads\source.msix
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
winget source update
Remove-Item ~\Downloads\source.msix

$programs = @{
	"Microsoft" = @(
		"Office",
		"OneDrive",
		"VisualStudioCode",
		"PowerShell", # admin
		"DevHome",
		"PCManager",
		"WindowsTerminal"
	);
	"Notion" = @(
		"Notion",
		"NotionCalendar"
	);
	"Adobe" = @(
		"CreativeCloud",
		"Acrobat.Pro"
	);
	"Python" = "Python.3.12";
	"JanDeDobbeleer" = "OhMyPosh";
	"MSYS2" = "MSYS2";
	"Git" = "Git";
	"GitHub" = "GitHubDesktop";
	"Neovim" = "Neovim";
	"Discord" = "Discord";
	"" = @(
		"9PP9GZM2GN26", # unison
		"XPFD4T9N395QN6" # photoshop
	)
}

# apple
# netflix

foreach ($key in $programs.Keys) {
	foreach ($value in $programs[$key]) {
		if (-not $key) {
			winget install $value --accept-package-agreements --accept-source-agreements
		} else {
			winget install "$key.$value" --accept-package-agreements --accept-source-agreements
		}
	}
}

Remove-Item "$ENV:USERPROFILE\Desktop\Notion.lnk" -Force
Remove-Item "$ENV:USERPROFILE\Desktop\Notion Calendar.lnk" -Force
Remove-Item "$ENV:USERPROFILE\Desktop\Discord.lnk" -Force

@"
Start-BitsTransfer -Source "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip"
Expand-Archive CascadiaCode.zip
Move-Item CascadiaCode\* C:\Windows\Fonts
Remove-Item CascadiaCode.zip
$user_profile = Resolve-Path "$ENV:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json"
$face = '"defaults": 
        {
            "font": 
            {
                "face": "CaskaydiaCove Nerd Font"
            }
        }'
cat $user_profile | foreach { $_ -replace '"defaults":.*{.*}', $face } > (Resolve-Path $user_profile)
New-Item -Force -Type File -Path $PROFILE
"oh-my-posh init pwsh | Invoke-Expression" > (Resolve-Path $PROFILE)

Start-Process cmd.exe -ArgumentList '/c git clone https://github.com/NvChad/starter %USERPROFILE%\AppData\Local\nvim && nvim'
"@
:Install:

:End
pause >nul
del "%~f0"