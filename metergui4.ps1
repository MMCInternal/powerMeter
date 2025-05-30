
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
$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
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
$directory = Split-Path $filePath
$fullPathWithoutExtension = Join-Path $directory $fileNameWithoutExtension
$datafilename = $fileNameWithoutExtension+'data.txt'
if (-not($directory -match ".\\$")) {Write-Output "The last character is not a drive." ; $directory = $directory+'\'}
$global:datafilepath = $directory+$datafilename
#Write-Host 'full path no exxt' $fullPathWithoutExtension
Write-Host 'directory' $directory
Write-Host 'file no ext' $fileNameWithoutExtension
write-host $datafilename

$label1.Text = "File Selected to Process:`r`n $filepath"
$label2.Text = "Data File Created: `r`n $global:datafilepath"
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

if (Test-Path $global:datafilepath) {
    # Delete the file
    Remove-Item $global:datafilepath -Force
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
$opendatafilebutton.text = "Open $global:datafilepath"
$opendatafilebutton.Visible = $true

}


Function Opendatafile {
write-host 'opendatafile'+ $global:datafilepath
Start-Process 'notepad.exe' -ArgumentList $global:datafilepath

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

$opendatafilebutton =  New-Object windows.forms.button
$opendatafilebutton.top = $exitbutton.top; $opendatafilebutton.Left = $GetFilebutton.left - $exitbutton.Width - 10
$opendatafilebutton.Height = $GetFilebutton.Height; $opendatafilebutton.Width = $GetFilebutton.width 
$opendatafilebutton.text = "open $($global:datafilepath)"
$opendatafilebutton.Visible = $false
$opendatafilebutton.anchor = "Right"
$opendatafileonclick = {Opendatafile}
$opendatafilebutton.add_click($opendatafileonclick)


$buttonpanel.Controls.add($exitbutton)
$buttonpanel.Controls.Add($GetFilebutton)
$buttonpanel.controls.add($opendatafilebutton)
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

