# Set PS Gallery as Trusted if not
If ((Get-psrepository -Name PSGallery).InstallationPolicy -eq "Untrusted") {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation "https://www.powershellgallery.com/api/v2"
}

# Update windows via cli | Drew Burgess HDS 2024 | Huge thanks to MS and PS Gallery
$mod = Get-Module -ListAvailable -Name "PSWindowsupdate" -ErrorAction SilentlyContinue
If ($mod -ne $null) {
    if (-not(Get-PackageProvider -Name "NuGet" -Verbose -ErrorAction SilentlyContinue -ListAvailable -Force)) { Install-PackageProvider -Name NuGet -Verbose -Force -ErrorAction SilentlyContinue }
    # If module update available
    If (-not($mod.Version -ge "2.2.1.4")) {
        Write-Host "Windows Update Found`n`n" -ForegroundColor Cyan -BackgroundColor Black
        Update-Module "PSWindowsUpdate" -Force -Verbose
        Clear-Host
    }
    # Module Exists
    Import-Module -Name "PSWindowsupdate" -Verbose -Force
    clear-host
}
else {
    Install-Module -Name "PSWindowsupdate" -Repository PSGallery -Force
    Import-Module -Name "PSWindowsupdate" -Verbose -Force
    clear-host
}

Get-WindowsUpdate -Verbose -Install -AcceptAll -IgnoreReboot