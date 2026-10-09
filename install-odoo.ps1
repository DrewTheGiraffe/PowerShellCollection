#requires -runasadministrator
<#
.SYNOPSIS
Install odoo inside Ubuntu-24.04 on WSL2
.AUTHOR
DREW BURGESS | AR.AI
.SOURCES
- https://www.odoo.com/documentation/master/administration/on_premise/source.html
#>

Function Press-AnyKeyToContinue {
    Write-Host "Press any key to continue..."
    Read-Host
}

Function get-nssm {
    # Moved away from scheduled tasks because its such a pain to deal with... 
    If (-not(Test-Path -Path "$env:PROGRAMFILES\nssm" -ErrorAction SilentlyContinue)) {
        If (-not(Get-item -Path "$env:USERPROFILE\Downloads\nssm.zip")) {
            Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "$env:USERPROFILE\Downloads\nssm.zip" -Verbose
        }
        If (-not(Test-Path -Path "$env:USERPROFILE\Downloads\nssm-2.24")) {
            Expand-Archive -Path "$env:USERPROFILE\Downloads\nssm.zip" -DestinationPath "$env:USERPROFILE\Downloads" -Verbose -Force
            Start-Sleep -Milliseconds 100
            Rename-Item -Path "$env:USERPROFILE\Downloads\nssm-2.24" -NewName "nssm" -Force
            If (-not(Test-Path -Path "$env:PROGRAMFILES\nssm")) {
                Move-Item -Path "$env:USERPROFILE\Downloads\nssm" -Destination "$env:PROGRAMFILES" -Verbose -Force
            }
        }
        # Update PATH with NSSM
        If (-not($env:PATH).Contains(";C:\Program Files\nssm\win64")) {
            $env:PATH += ';C:\Program Files\nssm\win64'
            Write-Host "Added NSSM to PATH" -ForegroundColor Green
        }
        # When finished installing...
        return $true
    }
    # If already installed...
    return $true
}

Function setup-odooproxy {

    # SSH Proxy script has obviously never ran.. so lets run it until its finshed. this will cause system restarts. a lot of them.
    If (-not(Test-Path -Path "C:\ScheduledTasks\log.txt")) {
        Start-Process -Wait -pspath powershell.exe -ArgumentList '& "\\arai-prodserver\netshare\ps\wsl\install-wsl2_sshproxy.ps1"' -Verb RunAs -Verbose
    }

    # Setup Proxy to Odoo for physical network connections
    $scriptcode = @"
`$Date` = "`$(Get-Date)` - Logging started" 
`$Date` | Out-File $env:SYSTEMDRIVE\ScheduledTasks\odoolog.txt -Append
powershell.exe -Command { 
# Script for pre-boot scheduled tasks odoo proxy enable for wsl2 | Drew Burgess 2025
# Uncomment these two lines if you are not using a custom distro with ssh already setup...
#wsl.exe --distribution "`$WslInstanceName`" --user root /bin/sh -c 'apt install ssh -y'
#wsl.exe --distribution "`$WslInstanceName`" --user root /bin/sh -c '/etc/init.d/ssh start'
`$WslInstanceName` = "Ubuntu-24.04"
# Enable service only needs to be ran once, we are currently running it above during initial setup
#wsl --distribution "`$WslInstanceName`" --user root /bin/sh -c 'systemctl enable ssh'
wsl --distribution "`$WslInstanceName`" --user root /bin/sh -c 'systemctl restart ssh'
`$wsl_ip` = (wsl --distribution "`$WslInstanceName`" hostname -I).trim()
netsh interface portproxy reset
Start-Sleep -Seconds 3
netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=22 connectaddress=`$wsl_ip`
netsh interface portproxy add v4tov4 listenport=8069 listenaddress=0.0.0.0 connectport=8069 connectaddress=`$wsl_ip`
Start-Process "wsl.exe" -ArgumentList "-d `$WslInstanceName` --exec bash" -WindowStyle Hidden
If (-not(get-netfirewallrule -Name "Allow odoo to WSL Inbound" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "Allow odoo to WSL Inbound" -Direction Inbound -Enabled True -Profile Private -EdgeTraversalPolicy Allow -DisplayName "Allow odoo to WSL Inbound" -Action Allow -LocalPort 8069 -Protocol TCP
}
If (-not(Get-NetConnectionProfile).NetworkCategory -eq "Private") {
        Set-NetConnectionProfile -NetworkCategory Private
    }
} *>> $env:SYSTEMDRIVE\ScheduledTasks\odoolog.txt
"@
    If (-not(Test-Path -Path "$env:SYSTEMDRIVE\ScheduledTasks")) {
        New-Item -Path "$env:SYSTEMDRIVE" -Name "ScheduledTasks" -ItemType "directory" -Force | Out-Null
    }
    If (-not(Test-Path -Path "$env:SYSTEMDRIVE\ScheduledTasks\connectto-odoo.ps1")) {
        New-Item -Path "$env:SYSTEMDRIVE\ScheduledTasks" -Name "connectto-odoo.ps1" -ItemType "file" -Value ($scriptcode) -Force | Out-Null
    }
    If (get-nssm) {
        $service = "ODOOProxySVC"
        If ((Get-Service -Name $service -ErrorAction SilentlyContinue) -eq $null) {
            [System.String]$username = Read-Host "Enter username for service : ODOOProxySVC to run with"
            [System.String]$password = Read-Host "Enter password for service : ODOOProxySVC to run with"
            # Install service with PowerShell as the executable
            nssm install ODOOProxySVC "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" 
            # Set the PowerShell script as the argument
            nssm set ODOOProxySVC AppParameters "-ExecutionPolicy Bypass -File C:\ScheduledTasks\connectto-odoo.ps1"
            # Set Service start automatically on system start
            nssm set ODOOProxySVC Start SERVICE_AUTO_START
            # Set Service to exit normally when finished instead of attempting to restart on exit.
            nssm set ODOOProxySVC AppExit Default Exit
            # Set the service to run under the current user (replace with a specific user if necessary)
            nssm set ODOOProxySVC ObjectName ".\$username" "$password" 
            # Set Description for Service
            nssm set ODOOProxySVC Description "ODOOProxySVC will run once at system start with user specified administrator credentials. It will execute C:\ScheduledTasks\connectto-odoo.ps1"
            Start-Sleep -Seconds 2 
            If ((Get-Service -Name "ODOOProxySVC" -ErrorAction SilentlyContinue).Status -ne "Running") {
                Start-Process -Wait -pspath powershell.exe -ArgumentList "-command { "C:\ScheduledTasks\connectto-odoo.ps1" }" -Verb RunAs -Verbose
                start-service -Name "ODOOProxySVC" -Verbose #-ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "Log available " -NoNewline; Write-host "@C:\ScheduledTasks\odoolog.txt" -ForegroundColor Cyan;

}

Function install-odoo {
    
    If (-not(Get-Service -Name "ODOOProxySVC")) {
        setup-odooproxy
    }

    # Setup Ubuntu Environment for Odoo
    $WslInstanceName = "Ubuntu-24.04"
    # Update & Clean System
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'apt update && apt upgrade -y && apt autoremove -y'
    # Create Odoo Community Directory
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'mkdir -p "Odoo_Community" && cd "Odoo_Community"'
    # Install Clone Odoo
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'apt install git -y && git clone https://github.com/odoo/odoo.git'
    # Install Dependencies
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'sudo apt install python3 python3-pip postgresql postgresql-client libldap2-dev libpq-dev libsasl2-dev nodejs npm nano -y'
    # Create Postgres user as odoo wont let you use default user...
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'sudo -u postgres createuser -d -R -S $USER'
    # Create db with user...
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'createdb $USER'
    # Run odoo bash environment setup script
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'bash ./odoo/setup/debinstall.sh'
    # Node install rtlcss
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'npm install -g rtlcss'
    # Node Fund Packages
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'npm fund'
    # Install wkhtmltopdf 
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'apt install wkhtmltopdf -y'
    # Check postgresql service status
    wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'systemctl enable postgresql && systemctl status postgresql'
    Write-Host "Finished setting up $WslInstanceName for odoo..." -ForegroundColor Green
    Start-Sleep -Seconds 1
    Write-Host "Documentation available here for custom cli arguments:`nhttps://www.odoo.com/documentation/master/developer/reference/cli.html"
    $prompt = Read-Host "Would you like to run custom cli arguments to start the server?(Y/n)"
    If (-not($prompt -eq "Y" -or $prompt -eq "y")) {
        # Start odoo server initial setup
        #wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'python3 odoo-bin -d $USER -i base'
        # Create custom linux service for odoo to run automatically... (As a service)
        If (-not(wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'service --status-all | grep odoo')) {
            # Create odoo service file
            wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'cd / && touch "/etc/systemd/system/odoo.service" && printf "[Unit]\nDescription=Odoo-bin server\nAfter=multi-user.target\n\n[Service]\nType=simple\nRestart=always\nExecStart=/usr/bin/python3 /Odoo_Community/odoo/odoo-bin -d $USER -i base\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/odoo.service'
            # Install Service to systemctl
            wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'systemctl daemon-reload && systemctl enable odoo.service && systemctl start odoo'
        }
    }
    else {
        # Start odoo server | Custom CLI Arguments
        wsl --distribution "$WslInstanceName" --user root /bin/sh -c 'python3 odoo-bin `$prompt`'
    }
}