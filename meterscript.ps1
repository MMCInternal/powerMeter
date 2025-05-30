
# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Create a new process with elevated privileges
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "powershell";
    $newProcess.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"";
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit;
}



Add-Type -AssemblyName System.Windows.Forms

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
$OpenFileDialog.Filter = "Text files (*.log)|*.log"

if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $Filepath = $OpenFileDialog.FileName
    Write-Output "You selected: $Filepath"
} else {
    Write-Output "No file selected."
    exit
}

#
#$filepath = "d:\logx.log"
$logfile = Get-Content -Path $filepath

$datafile = "c:\datafile.txt"
if (Test-Path $datafile) {
    # Delete the file
    Remove-Item $datafile -Force
    }

$numberArray= @()
$dataArray =@()
#$dave1 = $dave -replace "^..", ""
$decimalFlag = 0
$indexcounter= 0

#multiple loops to parse logfile to fish out power info
foreach ($TextLine in $logfile){ Write-host $TextLine
       #reset counters
       $indexcounter=0
       Clear-Variable -Name NumberArray
       #check for numeric content assume this is data
       if ($TextLine -match "^[0-9\s]+$"){
        # break substring for power data out
        $numberArray += $textline.Substring(26,12)
        $numberarray2 = $numberarray.Split()
            foreach ($element in $numberarray2){
                switch ($true){
                ($element -eq '00'){
                   if ($decimalflag -eq 1){
                        $element2 = $element -replace '00','.0'
                        $numberarray2[$indexcounter] = $element2
                        $decimalFlag = 0
                        break
                        }
                   else{
                   $element2 = $element -replace '00','0'
                   $numberarray2[$indexcounter] = $element2
                   $decimalFlag = 0
                   break
                        }
                   }
                ($decimalFlag -eq 1){
                    $element2 = $element -replace '0','.'
                    $numberarray2[$indexcounter] = $element2 
                    Write-host $element2
                    $decimalFlag = 0
                    break
                    }
                ($element -lt 10){ $element2 = $element -replace '0',''    
                   $numberarray2[$indexcounter] = $element2 
                   $decimalflag = 0
                   break
                    }
                ($element -ge 10){
                   $decimalFlag = 1
                   if ($element -eq '11'){
                   $element2 = $element -replace '11','1'
                   $numberarray2[$indexcounter] = $element2
                   break
                    }
                    else{$element2 = $element -replace '1',''
                   $numberarray2[$indexcounter] = $element2
                   break
                    }
 
                }
           }   
           $indexcounter++
           } 
#put array back together
$finalnumber = $numberarray2 -join ""
#Write to file
Add-Content -Path $datafile -Value $finalnumber
#reset counters
$numberarray2.clear() 
$finalnumber= $null
}
}
#Suck in data file and calc avg
$datafile2 = Get-Content -Path $datafile
$datafile2 | Measure-Object -Average -Maximum -Minimum 
#$datafile2 | Measure-Object -Maximum




# Calculate the mean (average)
$mean = ($datafile2 | Measure-Object -Average).Average

# Calculate the sum of squared differences from the mean
$sumOfSquares = 0
foreach ($value in $datafile2) {
    $sumOfSquares += [math]::Pow(($value - $mean), 2)
}

# Calculate the variance
$variance = $sumOfSquares / ($datafile2.Count - 1)

# Calculate the standard deviation
$standardDeviation = [math]::Sqrt($variance)

# Output the standard deviation
write-host 'standard deviation: ' $standardDeviation

