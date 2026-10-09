#requires -runasadministrator

<#
.SYNOPSIS
Download and Deploy PostgreSQL for Windows
.AUTHOR
DREW BURGESS | ARAI 2025
.SOURCES
- https://stackoverflow.com/questions/27107557/what-is-the-default-password-for-postgres/27108276#27108276
- https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
#>

Start-Transcript -Path "$env:SYSTEMDRIVE\postgresql.txt" -Append -Force -NoClobber | Out-Null

Function PathExists([System.String]$FullPath) {
    If (Test-Path -Path $FullPath -ErrorAction SilentlyContinue) {
        return $true
    }
    else {
        return $false
    }
}

Function install-postgresql {
    # Add PostgreSQL db location to host
    If (-not(PathExists -FullPath "$env:USERPROFILE\Documents\PGDATA")) {
        New-Item -Path "$env:USERPROFILE\Documents" -Name "PGDATA" -ItemType "directory" -Force | Out-Null
    }
    # Download and Install PostgreSQL
    If (-not(PathExists -FullPath "$env:PROGRAMFILES\PostgreSQL\17\bin")) {
        $prmpt = Read-Host -Prompt "Would you like to select your version manually? (Y/n)"
        If ($prmpt -eq "Y" -or $prmpt -eq "y") {
            Write-Host "Visit " -NoNewline; Write-Host "https://www.enterprisedb.com/downloads/postgres-postgresql-downloads" -ForegroundColor Green -NoNewline
            Write-Host " for available installer downloads"
			Write-Host "Place download in : $env:USERPROFILE\Downloads\postgresql-windows-x64.exe"
            PAUSE
        }
        Invoke-WebRequest -Uri "https://sbp.enterprisedb.com/getfile.jsp?fileid=1259402" -OutFile "$env:USERPROFILE\Downloads\postgresql-windows-x64.exe" -Verbose
        Start-Sleep -Seconds 2
        Write-Host "Leave all options default and install everything. Remember to grab username and generated password from the output.." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Set-location "$env:USERPROFILE\Downloads"
        & ".\postgresql-windows-x64.exe"
        # Add PostgreSQL to Path
        If (-not($env:PATH -contains "$env:PROGRAMFILES\PostgreSQL\17\bin")) {
            $env:PATH += (";" + "$env:PROGRAMFILES\PostgreSQL\17\bin")
            Write-Host "Added PostgreSQL to Path" -ForegroundColor Green
        }
        $pgpass = Read-Host "Enter Postgresql password"
        If (-not($pgpass -eq $null)) {
            $processid = (Get-NetTCPConnection | Where-Object { $_.LocalPort -eq 5432 }).OwningProcess
            $id1 = $processid[0]
            $id2 = $processid[1]
            If ($id1 -match $id2) {
                $processid = $null
                $processid = $id1
            }
            # ChatGPT fixed this bug where the installer has the SQL server "running" but its unable to be reached.
            Stop-Process -Id $processid -Force -Verbose
        }
        set-location -Path "$env:PROGRAMFILES\PostgreSQL\17\bin" -ErrorAction SilentlyContinue
        Start-Process -FilePath "." -ArgumentList 'pg_ctl -D "$env:USERPROFILE\Documents\PGDATA" -U PGADMIN -P $pgpass -N MSFDB start'
    }
    Stop-Transcript | Out-Null
    Write-Host "PostgreSQL:`n`nUSERNAME : PGADMIN`nPASSWORD : $pgpass`nSERVER   : 127.0.0.1`nPORT     : 5432`nDBDIR    : $env:USERPROFILE\Documents\PGDATA" -ForegroundColor Cyan
}
install-postgresql