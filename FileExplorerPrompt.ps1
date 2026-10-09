

Add-Type -AssemblyName system.Windows.Forms
$SetBackupLocation = New-Object System.Windows.Forms.SaveFileDialog
$SetBackupLocation.InitialDirectory = [Environment]::GetFolderPath('C:\temp')
$SetBackupLocation.Title = 'File Explorer - Save File Location'
$Extention = $SetBackupLocation.AddExtension = ".EXE", ".ps1", ".txt"
$SetBackupLocation.FileName = 'Location.txt'
$rc = $SetBackupLocation.ShowDialog()
 
if ($rc -eq [System.Windows.Forms.DialogResult]::OK)
 
{
$BackupLocation = $SetBackupLocation.FileName
$BackupLocation = $BackupLocation.Replace('Location', "")
}
 
echo $BackupLocation
Pause #To look at the result
