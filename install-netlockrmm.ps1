#requires -runasadministrator

<#
.SYNOPSIS
Install NetlockRMM for Windows server
.AUTHOR
DREW BURGESS | AR.AI
.SOURCES

#>

# If user has a netlock product package / URL link
Function get-product {
    $prmpt = Read-Host "Enter package download url or press enter to skip. (optional)"
    If (-not($prmpt -eq $null)) {
        If (-not(Test-Path "$env:USERPROFILE\Documents\docker")) { New-Item -Path "$env:USERPROFILE\Documents" -Name "docker" -ItemType "directory" -Force | Out-Null; }
        If (-not(Test-Path "$env:USERPROFILE\Documents\docker\docker-netlockwindows")) { New-Item -Path "$env:USERPROFILE\Documents\docker" -Name "docker-netlockwindows" -ItemType "directory" -Force | Out-Null }
        If (-not(Test-Path "$env:USERPROFILE\Documents\docker\docker-netlockwindows\netlockrmm.zip")) {
            Invoke-WebRequest -Uri "$prmpt" -OutFile "$env:USERPROFILE\Documents\docker-netlockwindows\netlockrmm.zip" -Verbose
        }
    }
}