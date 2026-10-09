# All scripts easily invocable remotely
## Windows (elevated):
```
Powershell.exe -executionpolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/DrewTheGiraffe/PowerShellCollection/refs/heads/main/<script_name>.ps1')"
```
## macOS
```
if ! command -v pwsh >/dev/null 2>&1; then brew install --cask powershell fi pwsh -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/DrewTheGiraffe/PowerShellCollection/refs/heads/main/<script_name>.ps1')"
```
## Linux (Debian)
```
if ! command -v pwsh >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y wget . /etc/os-release wget -q https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb -O packages-microsoft-prod.deb sudo dpkg -i packages-microsoft-prod.deb rm packages-microsoft-prod.deb sudo apt-get update && sudo apt-get install -y powershell fi pwsh -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/DrewTheGiraffe/PowerShellCollection/refs/heads/main/<script_name>.ps1')"
```
