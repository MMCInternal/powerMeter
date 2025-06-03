
#Assembly to hide PS WIndow
$Script:showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru


Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

#global variables
$global:filepath = $null
$global:Datafilepath = $null
#Functions
Function getfile{
param ($result)

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
#$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
$OpenFileDialog.Filter = "Text files (*.log)|*.log"

if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $Filepath = $OpenFileDialog.FileName
    Write-Output "You selected: $Filepath"
} else {
    Write-Output "No file selected."
    exit
}

#get filename

$fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
$global:directory = Split-Path $filePath
$fullPathWithoutExtension = Join-Path $directory $fileNameWithoutExtension
$datafilename = $fileNameWithoutExtension+' data.txt'
$measurmentfilename = $fileNameWithoutExtension+' measurments.txt'
if (-not($directory -match ".\\$")) {Write-Output "The last character is not a drive." ; $directory = $directory+'\'}
$global:datafilepath = $directory+$datafilename
$global:measurmentFilePath = $directory+$measurmentfilename

#Write-Host 'full path no exxt' $fullPathWithoutExtension
Write-Host 'directory' $directory
Write-Host 'file no ext' $fileNameWithoutExtension
write-host $datafilename

$label1.Text = "File Selected to Process:`r`n $filepath"
$label2.Text = "Data File Created: `r`n $directory"
$txtbox.Text = "Opening $Filepath "#`r`n "# Replaces existing text
$txtbox.AppendText("datafile $datafilename") # Adds text to the end
$txtbox.AppendText(" `r`n Please wait")
$opendatafilebutton.Visible = $false
ParseLogfile


}

Function ParseLogFile{

#write-host $filepath
#write-host parselogfile $global:datafilepath
#write-host $global:Datafilepath
$logfile = Get-Content -Path $filepath

#if (Test-Path $global:datafilepath) {
#    # Delete the file
#    Remove-Item $global:datafilepath -Force
#    }
#foreach ($file in $global:datafilepath) {
for ($fileIndexCounter = 0; $fileIndexCounter -lt 100; $fileIndexCounter++) {
    if (Test-Path $datafilepath) {
        Write-Host "File exists"
        $datafilename = $filenamewithoutextension + ' data ' + $fileIndexCounter + ' .txt'
        $global:datafilepath = $directory+$datafilename
        Write-Host "File exists. Checking next file."
        #Add-Content -Path $global:datafilepath -Value $finalnumber
    }
    else {
        Write-Host "File does not exist Creating new file"
        Add-Content -Path $global:datafilepath -Value $finalnumber
        break
    }
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
Add-Content -Path $global:datafilepath -Value $finalnumber
#reset counters
$numberarray2.clear() 
$finalnumber= $null
        }
    }
#call displayinfo function
Displayinfo

}


Function Displayinfo{

$datafile2 = Get-Content -Path $global:datafilepath
 $measurements = $datafile2 | Measure-Object -Average -Maximum -Minimum  #|Out-String
 $temptext = "Count:     $($measurements.count)`r`nAverage:  $([math]::Round($measurements.Average,2))`r`nMinimum: $($measurements.minimum)`r`nMaximum: $($measurements.Maximum)"
 $txtbox.text= "$temptext"

# Calculate the mean (average)
$mean = (($datafile2 | Measure-Object -Average).Average)

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
$txtbox.AppendText("`r`nDeviation: $([math]::Round($standardDeviation,2))")

#turn on button to access data file created
#start-sleep -Seconds 5
$opendatafilebutton.text = "Open $directory"
$opendatafilebutton.Visible = $true
# Put all the measurments into an array and output to file for Leo.
$finalMeasurment = @(   $temptext,
                        "Deviation: $([math]::Round($standardDeviation,2))")
for ($fileIndexCounter = 0; $fileIndexCounter -lt 100; $fileIndexCounter++) {
    if (Test-Path $measurmentFilePath) {
        Write-Host "File exists"
        $measurmentfilename = $filenamewithoutextension + ' measurments ' + $fileIndexCounter + ' .txt'
        $global:measurmentFilePath = $directory+$measurmentfilename
        Write-Host "File exists. Checking next file."
    }
    else {
        Write-Host "File does not exist Creating new file"
        Add-Content -Path $global:measurmentFilePath -Value $finalMeasurment
        break
    }
}
}


Function Opendatafile {
write-host 'Open data location'+ $directory
start-process explorer.exe "$directory"
}

Function Show-Powershell()
{
$null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 10)
}
Function Hide-Powershell()
{
$null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 2)
}

function ShowConsole
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 5) #5 show
}

function HideConsole
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) #0 hide
}

#Grab all overages and move them to a new file. After moving them to a new file
function finalResult{
    # Create file picker dialog  
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Multiselect = $true
    $OpenFileDialog.Filter = "Text files (*.txt)|*.txt"
    $OpenFileDialog.Title = "Select in order. Off, Short Idle, Long Idle, Sleep."

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        # Init Variables
        $filesChosen = $OpenFileDialog.FileNames
        $localDirectory = Split-Path $filesChosen[0]
        if (-not($localDirectory -match ".\\$")) {$localDirectory = $localDirectory+'\'}
        write-host "Path to local directory: $localDirectory"
        $testResultfilename = $fileNameWithoutExtension+' testResults.txt'
        $global:testResultFilePath = $localDirectory+$testResultfilename
        $global:averages = @()
        $global:averages = New-Object double[] 4  # Initialize array with 4 elements
        $measurementIndex = 0
        
        # Delete existing test results file if it exists if it does remove it so we can replace it with the new results.
        if (test-path $global:testResultFilePath) {
            remove-item $global:testResultFilePath
        }
        # Loop through the files chosen and get the averages.
        foreach ($file in $filesChosen) {
            if ($measurementIndex -ge 4) {
                Write-Host "Warning: More than 4 measurement files selected. Only first 4 will be used."
                break
            }
            
            write-host "Working on file: $file"
            $content = Get-Content $file
            foreach ($line in $content) {
                if ($line -match "Average:\s*(\d+\.?\d*)") {
                    $global:averages[$measurementIndex] = [double]$matches[1]
                    break
                }
            }
            write-host "Path to final result file: $global:testResultFilePath"
            $fileName = Split-Path $file -Leaf
            $fileName = $fileName -replace '.txt', ''
            $finalResultFile = $fileName + " : " + $global:averages[$measurementIndex]
            add-content -path $global:testResultFilePath -value $finalResultFile
            $measurementIndex++
        }
        # Write out the averages to the console. Also do error checking for averages.
        write-host "Averages: $($global:averages[0]) $($global:averages[1]) $($global:averages[2]) $($global:averages[3])"
        if ($measurementIndex -gt 0) {
            $totalAverage = ($global:averages[0..($measurementIndex-1)] | Measure-Object -Average).Average
            write-host "Total average: $totalAverage"
        } else {
            $txtbox.AppendText("`r`nNo averages found in selected files")
        }
        # Check if 4 measurement files are selected
        if ($measurementIndex -eq 4) {
            $totalAnnualEnergy = totalAnnualEnergyFormula $global:averages[0] $global:averages[1] $global:averages[2] $global:averages[3]
            add-content -path $global:testResultFilePath -value "`nTotal Annual Energy Consumption: $totalAnnualEnergy"
            
            # Replace "measurments" with "Average" in the test results file
            $content = Get-Content $global:testResultFilePath
            $content = $content -replace "measurments", "Average"
            Set-Content $global:testResultFilePath -Value $content
        } else {
            Write-Host "Warning: Need exactly 4 measurement files for total annual energy calculation"
        }
    }
}

function totalAnnualEnergyFormula($value1, $value2, $value3, $value4){
    try {
        # Validate inputs are numbers and not null
        if ($null -eq $value1 -or $null -eq $value2 -or $null -eq $value3 -or $null -eq $value4) {
            throw "One or more input values are null"
        }
        
        if (-not ($value1 -is [ValueType]) -or -not ($value2 -is [ValueType]) -or 
            -not ($value3 -is [ValueType]) -or -not ($value4 -is [ValueType])) {
            throw "One or more input values are not numbers"
        }

        # Convert to doubles to ensure proper calculation
        $v1 = [double]$value1
        $v2 = [double]$value2 
        $v3 = [double]$value3
        $v4 = [double]$value4
        # Formula for total annual energy consumption
        $totalAnnualEnergy = 8760/1000 * ($v1 * 0.15 + $v4 * 0.45 + $v3 * 0.1 + $v2 * 0.3)
        return [math]::Round($totalAnnualEnergy, 2)
    }
    catch {
        write-host "Error in totalAnnualEnergyFormula: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}
#Hide-powershell
HideConsole
#Create a form

add-type -AssemblyName system.windows.forms

$form = New-Object windows.forms.form
$form.FormBorderStyle = "fixedtoolWindow"
$form.Text = "Meter GUI Window V4"
$form.StartPosition = "CenterScreen"
$form.Width = 500; $form.Height = 400

$buttonpanel = New-Object windows.forms.panel
$buttonpanel.Size = New-Object drawing.size @(400,40)
$buttonpanel.Dock = "Bottom"
$buttonpanel.Height = 140

#$buttonpanel2 = New-Object windows.forms.panel
#$buttonpanel2.Size = New-Object drawing.size @(400,40)
#$buttonpanel2.padding = New-Object drawing.padding @(140,0,0,0)
#$buttonpanel2.Dock = "Bottom"
#$buttonpanel2.Height = 280

$exitbutton = New-Object windows.forms.button
$exitbutton.Height = 60 ; $exitbutton.Width = 150
$exitbutton.Top = $buttonpanel.Height - $exitbutton.Height - 10

$exitbutton.left = $buttonpanel.width - $exitbutton.width - 10
$exitbutton.Text = "Exit"
$exitbutton.DialogResult = "cancel"
$exitbutton.Anchor = "Right"

$GetFilebutton = New-Object windows.forms.button
$getfilebutton.Top = $exitbutton.Top ; $GetFilebutton.left = $exitbutton.left - $exitbutton.width - 10
$GetFilebutton.Height = $exitbutton.Height; $GetFilebutton.Width = $exitbutton.Width
$getfilebutton.left = $exitbutton.left -$getfilebutton.width - 10
$getfilebutton.Text = "Open file created by meter"
#$GetFilebutton.Height = 30; $GetFilebutton.Width = 140
#$getfilebutton.DialogResult = "OK"
$getfilebutton.Anchor = "Right"
$getFileonclick = {getfile}
$GetFilebutton.add_click($getfileonclick)




$finalresultbutton = New-Object windows.forms.button
#$averagebutton.Top = $exitbutton.Top ; $averagebutton.left = $getfilebutton.left - $exitbutton.width - 10
$finalresultbutton.top = 0
$finalresultbutton.Height = $exitbutton.Height; $finalresultbutton.Width = $getfilebutton.Width
$finalresultbutton.left = $buttonpanel.width - $finalresultbutton.width - 10
$finalresultbutton.Text = "Final Result"
$finalresultbutton.Anchor = "Right"
$finalresultonclick = {finalResult}
$finalresultbutton.add_click($finalresultonclick)

$opendatafilebutton =  New-Object windows.forms.button
$opendatafilebutton.top = $exitbutton.top; $opendatafilebutton.Left = $GetFilebutton.left - $exitbutton.Width - 10
$opendatafilebutton.Height = $GetFilebutton.Height; $opendatafilebutton.Width = $GetFilebutton.width 
$opendatafilebutton.text = "open $($global:datafilepath)"
$opendatafilebutton.Visible = $false
$opendatafilebutton.anchor = "Right"
$opendatafileonclick = {Opendatafile}
$opendatafilebutton.add_click($opendatafileonclick)

#$buttonpanel2.Controls.add($exitbutton)
#$form.controls.add($buttonpanel2)

$buttonpanel.Controls.add($exitbutton)
$buttonpanel.Controls.Add($GetFilebutton)
$buttonpanel.controls.add($opendatafilebutton)
$buttonpanel.controls.add($finalresultbutton)
$form.controls.add($buttonPanel)

#$form.AcceptButton = $GetFilebutton
#$form.CancelButton = $exitbutton

$txtbox = new-object Windows.forms.textbox
$txtbox.top = 85; $txtbox.left = 25; $txtbox.width = 500 ;$txtbox.multiline = $true
$txtbox.BackColor = "#E8E8E8" ;$txtbox.BorderStyle = 'none'
$txtbox.Size = New-Object System.Drawing.Size 150,100
$txtbox.text = "No data to display"
$form.controls.add($txtbox)

$label1 = New-Object system.windows.forms.label
$label1.Top =10; $label1.left = 20; $label1.width = 500;$label1.Height = 30
$label1.Text = "File Selected to Process: None Yet"
$label1.Font = New-Object System.Drawing.Font($label1.Font.FontFamily, 10)

#$label1.BackColor = "blue"
$label2 = New-Object System.Windows.Forms.Label
$label2.Top = 45; $label2.Left = 20; $label2.Width = 500; $label2.Height = 30
$label2.Text = "Data File Created: None Yet"
$label2.Font = New-Object System.Drawing.Font($label2.Font.FontFamily, 10)
$form.Controls.Add($label1) ;$form.controls.add($label2)


$form.Activate()
$result = $form.ShowDialog()