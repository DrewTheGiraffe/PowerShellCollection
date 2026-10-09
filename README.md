# How to invoke update-windows.ps1 remotely
## Windows (elevated):
```
$s = (iwr -Uri 'https://raw.githubusercontent.com/DrewTheGiraffe/PowerShellCollection/refs/heads/main/update-windows.ps1').Content.TrimStart([char]0xFEFF); iex $s
```
### Note: Always inspect scripts before executing, especially when running as Administrator. 
### Warning: For educational / Personal use, I do not take any responsibility for damages to systems, networks, etc. Use at your own risk.
