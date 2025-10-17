$global:logcount = 0
$excludedFileExt = @(".log")
$files = Get-ChildItem -path ".\10632" -Recurse | Where-Object { -not $_.PSIsContainer }
function removeFiles
{
  foreach ($file in $files)
  {
    if ($excludedFileExt -notcontains $file.Extension)
    {
      write-Output "Removing file: $($file.FullName)"
      Remove-Item -Path $file.FullName -Force
      Write-Log -Message "Removed file: $($file.FullName)" -Level "INFO"
    } elseif ($excludedFileExt -contains $file.Extension)
    {
      Write-Output "Excluding file: $($file.FullName)"
      Write-Log -Message "Excluded file: $($file.FullName)" -Level "INFO"
      move-Item -Path $file.FullName -Destination ".\10632\" -Force
      Write-Output "Moved file: $($file.FullName) to .\10632\"
      Write-Log -Message "Moved file: $($file.FullName) to .\10632\" -Level "INFO"
    }
  }
}
function Write-Log
{
  param(
    [string]$Message,
    [string]$Level = "INFO",
    [string]$LogFile = "$PSScriptRoot\cleanup.log"
  )

  if ($global:logcount -le 0)
  {
    Add-Content -Path $LogFile -Value "`n--- New Log ---`n"
    $global:logcount++
  } else
  {
    $global:logcount++

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
  }
}
removeFiles
