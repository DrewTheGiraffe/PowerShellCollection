#require -runasadministrator

<#

.SYNOPSIS
Install GoPhish server for Windows from source.
.AUTHOR
Drew Burgess | 01.06.2025 | https://github.com/drewthegiraffe

#>

# Install 7Zip4PowerShell
# Source :    https://github.com/thoemmi/7Zip4Powershell
# PSGallery : https://www.powershellgallery.com/packages/7Zip4Powershell/2.7.0
If ((Get-Module -Name 7Zip4Powershell -ListAvailable -ErrorAction Ignore) -eq $null) {
    Install-Module -Name 7Zip4Powershell -Repository PSGallery -RequiredVersion "2.7.0" -Verbose -Scope AllUsers -Force
    Import-Module -Name 7Zip4Powershell -Verbose -Force
}

<#

Thanks to Ollama for explaining how the releases on GCC are broken down by definition:

For example, a release named x86_64-12.2.0-release-posix-seh-msvcrt-rt_v10-rev2 can be broken down as:

- x86_64:      64-bit target architecture
- 12.2.0:      GCC version 12.2.0
- posix:       POSIX threading model
- seh:         Structured Exception Handling
- msvcrt:      Microsoft Visual C Runtime
- rt_v10-rev2: MinGW-w64 runtime version 10, revision 2

#>
If (-not(Test-Path "$env:ProgramFiles\GCC" -ErrorAction Ignore)) {
    Invoke-WebRequest -Uri "https://github.com/niXman/mingw-builds-binaries/releases/download/14.2.0-rt_v12-rev0/x86_64-14.2.0-release-win32-seh-msvcrt-rt_v12-rev0.7z"`
    -OutFile "$env:USERPROFILE\Downloads\x86_64-14.2.0-release-win32-seh-msvcrt-rt_v12-rev0.7z" -Verbose

    Expand-7Zip -ArchiveFileName "$env:USERPROFILE\Downloads\x86_64-14.2.0-release-win32-seh-msvcrt-rt_v12-rev0.7z"`
    -TargetPath "$env:USERPROFILE\Downloads" -Verbose

    Rename-Item -Path "$env:USERPROFILE\Downloads\mingw64" -NewName "GCC" -Force
    Move-Item -Path "$env:USERPROFILE\Downloads\GCC" -Destination $env:ProgramFiles -Verbose -Force
}

# Get 1.19.8 GO for windows: https://go.dev/dl/go1.19.8.windows-amd64.msi
# Reason : https://github.com/gophish/gophish/issues/2837#issuecomment-1517941031
If (-not(Test-Path -Path "C:\Program Files\Go\bin")) {
    Invoke-WebRequest -Uri "https://go.dev/dl/go1.19.8.windows-amd64.msi" `
    -OutFile "$env:USERPROFILE\Downloads\go1.19.8.windows-amd64.msi" -Verbose
    msiexec.exe /i $env:USERPROFILE\Downloads\go1.19.8.windows-amd64.msi /passive /norestart
    Write-Host "Waiting for Go to be installed" -NoNewline
    Do {
        Write-Host "." -NoNewline
        Start-Sleep -Milliseconds 500
    }
    Until (Test-Path -Path "C:\Program Files\Go\bin")
}

# Get NSSM
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "$env:USERPROFILE\Downloads\nssm.zip" -Verbose
Expand-Archive -Path "$env:USERPROFILE\Downloads\nssm.zip" -DestinationPath "$env:USERPROFILE\Downloads" -Verbose -Force
Start-Sleep -Seconds 2
Rename-Item -Path "$env:USERPROFILE\Downloads\nssm-2.24" -NewName "nssm" -Force
Move-Item -Path "$env:USERPROFILE\Downloads\nssm" -Destination "$env:PROGRAMFILES" -Verbose -Force
# Update PATH with NSSM
If (-not($env:PATH).Contains(";C:\Program Files\nssm\win64")) {
    
    $env:PATH += ';C:\Program Files\nssm\win64'
    Write-Host "Added NSSM to PATH" -ForegroundColor Green
    Start-Sleep -Milliseconds 100

}
# Update PATH with GO
If (-not($env:PATH).Contains(";C:\Program Files\Go\bin")) {

    $env:PATH += ';C:\Program Files\Go\bin'
    Write-Host "Added Go to PATH" -ForegroundColor Green
    Start-Sleep -Milliseconds 100

}
# Update PATH with GCC
If (-not($env:PATH).Contains(";C:\Program Files\GCC\bin")) {

    $env:PATH += ';C:\Program Files\GCC\bin'
    Write-Host "Added GCC to PATH" -ForegroundColor Green
    Start-Sleep -Milliseconds 100

}

# Move Download to $env:USERPROFILE\Documents\GitHub
If (-not(Test-Path -Path "$env:USERPROFILE\Documents\GitHub\gophish-master" -PathType Container)) {

    Invoke-WebRequest -Uri "https://github.com/gophish/gophish/archive/refs/heads/master.zip" -OutFile "$env:USERPROFILE\Downloads\master.zip" -Verbose

    Expand-Archive -Path "$env:USERPROFILE\Downloads\master.zip" -DestinationPath "$env:USERPROFILE\Downloads\gophish" -Force -Verbose

    If (-not(Test-Path -Path "$env:USERPROFILE\Documents\GitHub")) {
        New-Item -Path "$env:USERPROFILE\Documents" -Name "GitHub" -ItemType "directory" -Verbose -Force
    }
    
    Move-Item -Path "$env:USERPROFILE\Downloads\gophish\gophish-master" -Destination "$env:USERPROFILE\Documents\GitHub" -Verbose -Force

}

# Set Script scope directory
Set-Location -Path "$env:USERPROFILE\Documents\GitHub\gophish-master" -ErrorAction SilentlyContinue

If ((Get-Location).Path -eq "$env:USERPROFILE\Documents\GitHub\gophish-master") {
    # Cleanup Downloads
    Remove-Item -Path "$env:USERPROFILE\Downloads\x86_64-14.2.0-release-win32-seh-msvcrt-rt_v12-rev0.7z" -Force -ErrorAction Ignore
    Remove-Item -Path "$env:USERPROFILE\Downloads\go1.19.8.windows-amd64.msi" -Force -ErrorAction Ignore
    Remove-Item -Path  "$env:USERPROFILE\Downloads\master.zip" -Force -ErrorAction Ignore
    Remove-Item -Path "$env:USERPROFILE\Downloads\nssm.zip" -Force -ErrorAction Ignore
}

# https://github.com/gophish/gophish#building-from-source
# If you are building from source, please note that Gophish requires Go v1.10 or above!
$goversion = go version
If ($goversion -eq "go version go1.19.8 windows/amd64") {
    $prompt = Read-Host -Prompt "Would you like to edit the server URL?(y/N)"
    If (($prompt) -eq "y" -or ($prompt) -eq "Y") {
        $editconfig = Start-Process -pspath notepad.exe -ArgumentList "$env:USERPROFILE\Documents\GitHub\gophish-master\config.json" -PassThru
        Write-Host "Waiting for config to be saved and closed" -NoNewline
        Do {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 3
        } Until ($editconfig.HasExited)
    }
    Start-Sleep -Milliseconds 500
    If (-not(Test-Path "$env:USERPROFILE\Documents\GitHub\gophish-master\gophish.exe" -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Host "`nBuilding GoPhish from Source..." -ForegroundColor Cyan
        start-process -wait -pspath go -ArgumentList "mod tidy" -NoNewWindow -ErrorAction SilentlyContinue
        start-process -wait -pspath go -ArgumentList "build" -NoNewWindow -ErrorAction SilentlyContinue
        Write-Host "`n`nGoPhish Server Client built from source successfully..." -ForegroundColor Green
    }
    If (Test-Path "$env:USERPROFILE\Documents\GitHub\gophish-master\gophish.exe" -PathType Leaf -ErrorAction SilentlyContinue) {
        # Clear-Host # Dont use this if you'd like to review the installation log in the cli window.
        Write-Host "Complete Initial Setup, login info will be posted on new cmd window." -ForegroundColor Green
        Start-Sleep -Seconds 2
        Write-Warning -Message "Close cmd window when finished with setting new admin password."
        Start-Sleep -Seconds 2
        # Define the path to the gophish executable
        $gophishPath = "$env:USERPROFILE\Documents\GitHub\gophish-master\gophish.exe"
        # Allow inbound traffic for TCP port 3333
        New-NetFirewallRule -DisplayName "Allow Gophish TCP 3333" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 3333 `
            -Action Allow `
            -Program $gophishPath `
            -Enabled True
        # Allow inbound traffic for TCP port 83
        New-NetFirewallRule -DisplayName "Allow Gophish TCP 83" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 83 `
            -Action Allow `
            -Program $gophishPath `
            -Enabled True
        Write-Host "Firewall rules created successfully for Gophish on ports 3333 and 83."
        $rungophish = Start-Process -FilePath "$env:USERPROFILE\Documents\GitHub\gophish-master\gophish.exe" -Verbose -PassThru
        Write-Host "Waiting for GoPhish Setup to finish..." -NoNewline
        Do { Write-Host "." -NoNewline; Start-Sleep -Seconds 3} Until ($rungophish.HasExited)
        # Create Service for Gophish
        If (-not(Get-Service -Name "GophishSVC" -ErrorAction SilentlyContinue)) {
            Write-Host "`nCreating Gophish Service to start automatically..." -ForegroundColor DarkCyan
            Start-Sleep -Seconds 1
            nssm install GophishSVC "$env:USERPROFILE\Documents\GitHub\gophish-master\gophish.exe"
            Start-Sleep -Seconds 2 
            If (Get-Service -Name "GophishSVC" -ErrorAction SilentlyContinue) {
                start-service -Name "GophishSVC" -Verbose
            }
        }
        # For Testing: Remove the service with : Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\GophishSVC" -Recurse -Force
        Write-Host "Server Config : " -NoNewline
        Write-Host "$env:USERPROFILE\Documents\GitHub\gophish-master\config.json" -ForegroundColor DarkCyan
        Write-Host "Resource Links Here: https://getgophish.com/documentation/"
        Write-Host "General Usage Documentation available here: https://docs.getgophish.com/user-guide/documentation"
        Write-Host "API Usage Documentation available here: https://docs.getgophish.com/api-documentation"
        Write-Host "Run the following command to start server manually : " -NoNewline 
        Write-Host "Start-Process -wait -pspath notepad.exe -ArgumentList `"$env:USERPROFILE\Documents\GitHub\gophish-master\config.json`" -verbose" -NoNewline -ForegroundColor DarkCyan
    }
    else {
        Write-Host "Unable to build gophish...Try Running script again..." -ForegroundColor Yellow
    }
}

