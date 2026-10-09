#requires -runasadministrator
<#
.SYNOPSIS
Deploy SuiteCRM for Windows... Build from source in docker.
.AUTHOR
DREW BURGESS | AR.AI
.SOURCES
- https://github.com/bitnami/containers/tree/main/bitnami/suitecrm
- https://github.com/bitnami/containers/blob/main/bitnami/suitecrm/docker-compose.yml
#>

Function Press-AnyKeyToContinue {
    Write-Host "Press any key to continue..."
    Read-Host
}

# Install Docker Desktop
Function get-dockerdesktop {
    $hn = $env:COMPUTERNAME
    # Install Docker before installing distros..
    If (-not(Test-Path "$env:PROGRAMFILES\Docker\Docker\Docker Desktop.exe")) {
        If (-not(Test-Path -Path "$env:USERPROFILE\Downloads\Docker Desktop Installer.exe")) {
            Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-windows" -OutFile "$env:USERPROFILE\Downloads\Docker Desktop Installer.exe" -Verbose
            Start-Sleep -Seconds 1
        }
        Start-Process -wait -FilePath "$env:USERPROFILE\Downloads\Docker Desktop Installer.exe" -ArgumentList "install --accept-license --always-run-service" -Verb RunAs
    }
    else {
        Write-Host "Docker Desktop Present on " -NoNewline; Write-Host "$hn" -ForegroundColor Cyan -NoNewline; Write-Host "..."
    }
}

Function install-suitecrm {
    get-dockerdesktop
    $Downloads = "$env:USERPROFILE\Downloads"
    $Documents = "$env:USERPROFILE\Documents"
    # Setup Environent
    If (-not(Test-Path -Path "$Documents\docker")) {
        New-Item -Path "$Documents" -Name "docker" -ItemType "directory" -Force -Verbose | Out-Null
    }
    If (-not(Test-Path -Path "$Documents\docker\suitecrm")) {
        New-Item -Path "$Documents\docker" -Name "suitecrm" -ItemType "directory" -Force -Verbose | Out-Null
    }
    # Get Docker-Compose file : https://github.com/bitnami/containers/blob/main/bitnami/suitecrm/docker-compose.yml
    If (-not(Test-Path -Path "$Documents\docker\suitecrm\docker-compose.yml")) {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bitnami/containers/refs/heads/main/bitnami/suitecrm/docker-compose.yml" -OutFile "$Documents\docker\suitecrm\docker-compose.yml" -Verbose
    }
    If (-not(Get-Location).Path.Equals("$Documents\docker\suitecrm")) {
        Set-Location -Path "$Documents\docker\suitecrm"
    }
    $prompt = Read-Host -Prompt "Would you like to edit SuiteCRM docker-compose.yml(Y/n)"
    If ($prompt -eq "y" -or $prompt -eq "y") {
        Start-Sleep -Seconds 2
        Write-Host "`n`n`n`n`n`n`n`n`n`n`n`n"
        Write-Host "Settings for docker-compose.yml" -ForegroundColor DarkCyan
        Write-Host "Under suiteCRM:"; Write-Host "Ports:`n - 18800:8080`n - 44300:8443" -ForegroundColor Cyan
        Write-Host "At the bottom of the page include the following outside of all containers:"; Write-Host "networks:`n suitecrm-network:`n  driver: bridge" -ForegroundColor Cyan
        Start-Process -Wait -pspath notepad.exe -ArgumentList "docker-compose.yml"
    }
    Press-AnyKeyToContinue
    #start-process -wait -pspath docker.exe -ArgumentList 'compose --env-file ".env" -f "docker-compose.yml" up -d --pull always --remove-orphans --force-recreate' -NoNewWindow
    start-process -wait -pspath docker.exe -ArgumentList 'compose -f "docker-compose.yml" up -d' -NoNewWindow
    $hostnetworks = Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.AddressFamily -eq "IPv4" } | Select -ExpandProperty IPAddress
    Write-Host "SuiteCRM Instance Available here:`n"
    Foreach ($ip in $hostnetworks) {
        Write-Host "http://${ip}:18800"
        Write-Host "https://${ip}:44300"
    }
    Write-Host "Default Credentials:" -ForegroundColor Cyan; Write-Host "username: user`npassword: bitnami"
}
install-suitecrm