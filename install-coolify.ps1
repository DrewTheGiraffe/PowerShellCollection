# Install Coolify on primary servers of future clusters
<#
.AUTHOR
Drew Burgess | AR.AI
.SOURCES
- https://coolify.io/docs/installation#_2-supported-operating-systems
- https://github.com/coollabsio/coolify
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
        Start-Process -wait -FilePath "$env:USERPROFILE\Downloads\Docker Desktop Installer.exe" -ArgumentList "install --accept-license --always-run-service" -Verb RunAs -ErrorAction SilentlyContinue
    }
    else {
        Write-Host "Docker Desktop Present on " -NoNewline; Write-Host "$hn" -ForegroundColor Cyan -NoNewline; Write-Host "..."
    }
}

# Prep Windows environment
Function install-coolify {
    get-dockerdesktop
    $Downloads = "$env:USERPROFILE\Downloads"
    $Documents = "$env:USERPROFILE\Documents"
    [System.Boolean]$Setupisneeded = $false
    If (-not(Test-Path -Path "$Documents\docker" -ErrorAction SilentlyContinue)) {
        New-Item -Path "$Documents" -Name "docker" -ItemType "directory" -Force | Out-Null
        $Setupisneeded = $true
    }
    If (-not(Test-path -Path "$Documents\docker\coolify" -ErrorAction SilentlyContinue)) {
        New-Item -Path "$Documents\docker" -Name "coolify" -ItemType "directory" -Force | Out-Null
        $Setupisneeded = $true
    }
    If ($Setupisneeded) {
         If (-not(Test-Path -Path "$Documents\docker\coolify\docker-compose.yml")) {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/coollabsio/coolify/refs/heads/main/docker-compose.windows.yml" -OutFile "$Documents\docker\coolify\docker-compose.yml" -Verbose
         }
         If (-not(Test-Path -Path "$Documents\docker\coolify\.env")) {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/coollabsio/coolify/refs/heads/main/.env.windows-docker-desktop.example" -OutFile "$Documents\docker\coolify\.env" -Verbose
         }
         # Create Coolify network if needed
         $coolifynetworkexists = docker network ls -q --filter name=coolify
         If (-not($coolifynetworkexists)) {
            Start-Process -Wait -pspath docker.exe -ArgumentList "network create coolify" -NoNewWindow
         }
         If (-not(Get-Location).Path.Equals("$Documents\docker\coolify")) {
            Set-Location -Path "$Documents\docker\coolify"
         }
         $EditDockerEnv = Read-Host -Prompt "Would you like to edit docker .env for Coolify(Y/n)"
         If ($EditDockerEnv -eq "Y" -or $EditDockerEnv -eq "y") {
            Start-Process -Wait -pspath notepad.exe -ArgumentList ".env"
         }
         $EditDockerCompose = Read-Host -Prompt "Would you like to edit docker-compose.yml for Coolify?(Y/n)"
         If ($EditDockerCompose -eq "Y" -or $EditDockerCompose -eq "y") {
            Start-Process -Wait -pspath notepad.exe -ArgumentList "docker-compose.yml" 
         }
         Write-Host "If prompted, make sure to click more info and check boxs for Private and Public Networks." -ForegroundColor Cyan
         Press-AnyKeyToContinue
         start-process -wait -pspath docker.exe -ArgumentList 'compose --env-file ".env" -f "docker-compose.yml" up -d --pull always --remove-orphans --force-recreate' -NoNewWindow
         $hostnetworks = Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.AddressFamily -eq "IPv4" } | Select -ExpandProperty IPAddress
         Write-Host "Coolify Instance Available here:`n"
         Foreach ($ip in $hostnetworks) {
            Write-Host "http://${ip}:8000"
         }
    }
    If ((Test-Path -Path "$env:USERPROFILE\Documents\docker\coolify" -ErrorAction SilentlyContinue) -and $Setupisneeded -eq $false) {
        If (-not(Get-Location).Path.Equals("$Documents\docker\coolify")) {
            Set-Location -Path "$Documents\docker\coolify"
        }
        Write-Host "If prompted, make sure to click more info and check boxs for Private and Public Networks." -ForegroundColor Cyan
        Press-AnyKeyToContinue
        start-process -wait -pspath docker.exe -ArgumentList 'compose --env-file ".env" -f "docker-compose.yml" up -d --pull always --remove-orphans --force-recreate' -NoNewWindow
        $hostnetworks = Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.AddressFamily -eq "IPv4" } | Select -ExpandProperty IPAddress
        Write-Host "Coolify Instance Available here:`n"
        Foreach ($ip in $hostnetworks) {
            Write-Host "http://${ip}:8000"
        }
    }
    If (-not(Get-location).Path.Equals("$env:SystemRoot\System32")) {
        Set-Location -Path "$env:SystemRoot\System32"
    }
}
install-coolify