add-type -AssemblyName system.windows.forms

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Multiselect = $true # Enable multiple file selection
$OpenFileDialog.Filter = "Text files (*.log)|*.log"


if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
{
  $selectedFiles = $OpenFileDialog.FileNames
  Write-Output "You selected: $($selectedFiles.Count) files"
}
Read-Host
