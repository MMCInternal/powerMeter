$compare = @("1 off measurments.txt", "2 5 min short idle measurments.txt", "3 15 min long idle measurments.txt", "4 30 min sleep measurments.txt", "testResults.txt")
foreach ($file in $compare)
{
  Write-Host "Comparing $file"
  $fileA = Get-ChildItem F:\scripting\Powershell\powerMeter2.0\powerMeter -Recurse | Where-Object {$_.Name -Like "*$file"} | %{$_.FullName}
  $fileB = Get-ChildItem F:\scripting\Powershell\powerMeter -Recurse | Where-Object {$_.Name -Like "*$file"} | %{$_.FullName}
  try
  {
    if ($(Get-FileHash $fileA).Hash -ne $(Get-FileHash $fileB).Hash)
    {
      Write-Output "Files $fileA and $fileB aren't equal" - foregroundcolor red
    } else
    {
      write-host "Matches" -foregroundcolor green
    }
  }
  
  catch
  {
    <#Do this if a terminating exception happens#>
    if ($_.Exception.GetType().Name -eq "FileNotFoundException" -or $_.Exception.GetType().Name -eq "ParameterBindingValidationException")
    {
      Write-Host "File not found. Check for misspelling!" -foregroundcolor red
    } else
    {
      Write-Host "Uncommon error occurred" -foregroundcolor DarkRed
      Write-Host "Error: $($_.Exception.Message)" -foregroundcolor red
      Write-Host "Type: $($_.Exception.GetType().Name)" -foregroundcolor red
    }
  }
}
read-host "Press enter to exit"
