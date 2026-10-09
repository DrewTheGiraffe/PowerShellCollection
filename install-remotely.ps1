<#
.SYNOPSIS
Install Remotely | docker-compose Edition
.AUTHOR
DREW BURGESS | AR.AI
.SOURCES
- https://github.com/immense/Remotely/tree/master
#>

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

Function Press-AnyKeyToContinue {
    Write-Host "Press any key to continue..."
    Read-Host
}

Function append-proxyservice {
    If (-not(Test-Path -Path "$env:SYSTEMDRIVE\ScheduledTasks")) {
        New-Item -Path "$env:SYSTEMDRIVE" -Name "ScheduledTasks" -ItemType "directory" -Force | Out-Null
    }
    # Super hacky way to append to the middle of the file.. But it works...
    $checkforstring = Get-Content -Path "C:\ScheduledTasks\enable-wslssh.ps1" -Force -ErrorAction SilentlyContinue | ForEach-Object { If ($_.contains("netsh interface portproxy add v4tov4 listenport=5000 listenaddress=0.0.0.0 connectport=5000 connectaddress=$wsl_ip")) { return $true; break; } }
    If (-not($checkforstring -eq $true -or $checkforstring -ne $null)) {
        $remotelyproxyrule = @"
Start-sleep -Seconds 3
netsh interface portproxy add v4tov4 listenport=5000 listenaddress=0.0.0.0 connectport=5000 connectaddress=`$wsl_ip`
If (-not(get-netfirewallrule -Name "Allow remotely to WSL Inbound" -ErrorAction SilentlyContinue)) { 
    New-NetFirewallRule -Name "Allow Remotely to WSL Inbound" -Direction Inbound -Enabled True -Profile Private -EdgeTraversalPolicy Allow -DisplayName "Allow Remotely to WSL Inbound" -Action Allow -LocalPort 5000 -Protocol TCP 
}
"@
        (Get-Content -Path "C:\ScheduledTasks\enable-wslssh.ps1" -raw -Force -ErrorAction SilentlyContinue) -replace "Start-Sleep -Seconds 3", $remotelyproxyrule | Set-Content -Path "C:\ScheduledTasks\enable-wslssh.ps1" -Force
    }
}

Function install-remotely {
    get-dockerdesktop
    $Downloads = "$env:USERPROFILE\Downloads"
    $Documents = "$env:USERPROFILE\Documents"
    [System.Boolean]$Setupisneeded = $true
    If (-not(Test-Path -Path "$Documents\docker" -ErrorAction SilentlyContinue)) {
        New-Item -Path "$Documents" -Name "docker" -ItemType "directory" -Force | Out-Null
        $Setupisneeded = $true
    }
    If (-not(Test-path -Path "$Documents\docker\remotely" -ErrorAction SilentlyContinue)) {
        New-Item -Path "$Documents\docker" -Name "remotely" -ItemType "directory" -Force | Out-Null
        $Setupisneeded = $true
    }
    If ($Setupisneeded) {
        If (-not(Test-Path -Path "$Documents\docker\remotely\docker-compose.yml")) {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/immense/Remotely/master/docker-compose/docker-compose.yml" -OutFile "$Documents\docker\remotely\docker-compose.yml" -Verbose
        }
        If (-not(Get-Location).Path.Equals("$Documents\docker\remotely")) {
            Set-Location -Path "$Documents\docker\remotely"
        }
        $EditDockerCompose = Read-Host -Prompt "Would you like to edit docker-compose.yml for Remotely?(Y/n)"
        If ($EditDockerCompose -eq "Y" -or $EditDockerCompose -eq "y") {
            Start-Process -Wait -pspath notepad.exe -ArgumentList "docker-compose.yml" 
        }
        Write-Host "If prompted, make sure to click more info and check boxs for Private and Public Networks." -ForegroundColor Cyan
        Press-AnyKeyToContinue
        append-proxyservice
        Start-Process -Wait -pspath docker.exe -ArgumentList "compose up -d" -NoNewWindow
        $hostnetworks = Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.AddressFamily -eq "IPv4" } | Select -ExpandProperty IPAddress
        Write-Host "Remotely Instance Available here:`n"
        Foreach ($ip in $hostnetworks) {
            Write-Host "http://${ip}:5500"
        }
    }
}
install-remotely