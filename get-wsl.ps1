# Manage WSL installation | Drew Burgess 2024
if (((Get-WindowsOptionalFeature -Online -FeatureName '*linux*' -ErrorAction Ignore | Select-Object FeatureName -ErrorAction Ignore).FeatureName) -ne $null) {
    
    Write-Host "Windows Subsystem for linux detected..." -ForegroundColor Red

    $prmpt = Read-Host -Prompt "Uninstall Windows Subsystem For Linux (Y/n)"

    If ($prmpt -eq "y" -or $prmpt -eq "Y") {
        
        Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -Remove -NoRestart -Verbose
    
    }

}
else {
    
    $prmpt = Read-Host -Prompt "Install Windows Subsystem For Linux (Y/n)"

    If ($prmpt -eq "y" -or $prmpt -eq "Y") {
    
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -Verbose

    }

}

Write-Host "`nScript Finished" -ForegroundColor Green