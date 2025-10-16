
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
$global:directory = $null
$global:e = 0
$global:z = 0
$global:measureQueue = @()
$global:filesProcessed = 0
#Functions
Function getfile
{
  param ($result)

  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.Multiselect = $true # Enable multiple file selection
  $OpenFileDialog.Filter = "Text files (*.log)|*.log"

  if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
  {
    $selectedFiles = $OpenFileDialog.FileNames
    Write-Output "You selected: $($selectedFiles.Count) files"
    $global:e = 0

    $expectedFiles = @('off', 'short idle', 'long idle', 'sleep')
    for ($i = 0; $i -lt 4; $i++)
    {
      if ($null -eq $selectedFiles[$i])
      {
        Write-Host "Error: Missing $($expectedFiles[$i]) measurement file"
        $txtbox.AppendText("`r`nError: Missing $($expectedFiles[$i]) measurement file")
        return
      }
    }
    # Sort selected files to match expected order
    $sortedFiles = @()
    foreach ($expectedName in $expectedFiles)
    {
      $matchingFile = $selectedFiles | Where-Object { 
        [System.IO.Path]::GetFileNameWithoutExtension($_) -like "*$expectedName*"
      }
      if ($matchingFile)
      {
        $sortedFiles += $matchingFile
      }
    }
    $selectedFiles = $sortedFiles
    Write-Host "Files sorted in expected order:"
    $selectedFiles | ForEach-Object { Write-Host ([System.IO.Path]::GetFileName($_)) }

    foreach($filePath in $selectedFiles)
    {
      Write-Output "Processing: $filePath"
        
      #get filename for each file
      $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
      $global:directory = Split-Path $filePath
      $datafilename = $fileNameWithoutExtension+' data.txt'
      $measurmentfilename = $fileNameWithoutExtension+' measurments.txt'
      $global:dataDir = Join-Path -Path $directory -ChildPath "data"
      if(!(Test-Path $global:dataDir))
      {
        New-Item -ItemType Directory -Path $global:dataDir
      }
        
      if (-not($directory -match ".\\$"))
      {
        Write-Output "The last character is not a drive."
        $directory = $directory+'\'
      }

      # Set data file path to current directory
      $global:datafilepath = Join-Path $dataDir $datafilename
        
      # Set measurement file path one directory up
      $global:parentDirectory = Split-Path $directory -Parent
      if (-not($global:parentDirectory -match ".\\$"))
      {
        $global:parentDirectory = $global:directory+'\'
      }
      $global:measurmentFilePath = $global:parentDirectory+$measurmentfilename

      Write-Host 'directory' $directory
      Write-Host 'parent directory' $global:directory
      #Write-Host 'file no ext' $fileNameWithoutExtension
      write-host $datafilename

      # Update UI for current file
      $label1.Text = "File Selected to Process:`r`n $filepath`r`n"
      $label2.Text = "Data Files Created in: `r`n $directory"
      $txtbox.AppendText("`r`nProcessing $Filepath")
      $txtbox.AppendText("`r`nCreating datafile $datafilename")
      $opendatafilebutton.Visible = $false
        
      # Parse each log file
      ParseLogFile $filePath
    }
    
    $txtbox.AppendText("`r`nCompleted processing all files")
  } else
  {
    Write-Output "No files selected."
    return
  }

}

Function ParseLogFile
{
  param($currentFilePath)

  $logfile = Get-Content -Path $currentFilePath

  for ($fileIndexCounter = 0; $fileIndexCounter -lt 100; $fileIndexCounter++)
  {
    if (Test-Path $datafilepath)
    {
      Write-Host "File exists"
      $datafilename = $filenamewithoutextension + ' data ' + $fileIndexCounter + ' .txt'
      $global:datafilepath = $directory+$datafilename
      Write-Host "File exists. Checking next file."
    } else
    {
      Write-Host "File does not exist Creating new file"
      Add-Content -Path $global:datafilepath -Value $finalnumber
      write-host "File created: $global:datafilepath"
      break
    }
  }


  $numberArray= @()
  #if ($global:z -le 3)
  #   {
  $global:measureQueue += $global:datafilepath
  #   }
  #$dave1 = $dave -replace "^..", ""
  $decimalFlag = 0
  $indexcounter= 0

  #multiple loops to parse logfile to fish out power info
  foreach ($TextLine in $logfile)
  { #Write-host $TextLine
    #reset counters
    $indexcounter=0
    Clear-Variable -Name NumberArray
    #check for numeric content assume this is data
    if ($TextLine -match "^[0-9\s]+$")
    {
      # break substring for power data out
      $numberArray += $textline.Substring(26,12)
      $numberarray2 = $numberarray.Split()
      foreach ($element in $numberarray2)
      {
        switch ($true)
        {
          ($element -eq '00')
          {
            if ($decimalflag -eq 1)
            {
              $element2 = $element -replace '00','.0'
              $numberarray2[$indexcounter] = $element2
              $decimalFlag = 0
              break
            } else
            {
              $element2 = $element -replace '00','0'
              $numberarray2[$indexcounter] = $element2
              $decimalFlag = 0
              break
            }
          }
          ($decimalFlag -eq 1)
          {
            $element2 = $element -replace '0','.'
            $numberarray2[$indexcounter] = $element2 
            #Write-host $element2
            $decimalFlag = 0
            break
          }
          ($element -lt 10)
          { $element2 = $element -replace '0',''    
            $numberarray2[$indexcounter] = $element2 
            $decimalflag = 0
            break
          }
          ($element -ge 10)
          {
            $decimalFlag = 1
            if ($element -eq '11')
            {
              $element2 = $element -replace '11','1'
              $numberarray2[$indexcounter] = $element2
              break
            } else
            {$element2 = $element -replace '1',''
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
  Write-Host $filesProcessed
  Write-Host $global:measureQueue.Count
  Write-Host $global:measureQueue[$global:z]
  if ($global:filesProcessed -eq 3)
  {
    foreach($item in $global:measureQueue)
    {
      Displayinfo -currentFile $global:measureQueue[$global:z]
      $global:z++
    }
  }
  $global:filesProcessed++
}

Function Displayinfo
{
  param($currentFile)
  $datafile2 = Get-Content -Path $currentFile
  $measurements = $datafile2 | Measure-Object -Average -Maximum -Minimum  #|Out-String
  $temptext = "Count:     $($measurements.count)`r`nAverage:  $([math]::Round($measurements.Average,2))`r`nMinimum: $($measurements.minimum)`r`nMaximum: $($measurements.Maximum)"
  #$txtbox.text= "$temptext"
  $txtbox.text = ""

  # Calculate the mean (average)
  $mean = (($datafile2 | Measure-Object -Average).Average)

  # Calculate the sum of squared differences from the mean
  $sumOfSquares = 0
  foreach ($value in $datafile2)
  {
    $sumOfSquares += [math]::Pow(($value - $mean), 2)
  }

  # Calculate the variance
  $variance = $sumOfSquares / ($datafile2.Count - 1)

  # Calculate the standard deviation
  $standardDeviation = [math]::Sqrt($variance)

  # Output the standard deviation
  #write-host 'standard deviation: ' $standardDeviation
  #$txtbox.AppendText("`r`nDeviation: $([math]::Round($standardDeviation,2))")

  #turn on button to access data file created
  #start-sleep -Seconds 5
  $opendatafilebutton.text = "Open $directory"
  $opendatafilebutton.Visible = $true
  # Put all the measurments into an array and output to file for Leo.
  $finalMeasurment = @(   $temptext,
    "Deviation: $([math]::Round($standardDeviation,2))")
  for ($fileIndexCounter = 0; $fileIndexCounter -lt 100; $fileIndexCounter++)
  {
    if (Test-Path $measurmentFilePath)
    {
      Write-Host "File exists"
      $measurmentfilename = $filenamewithoutextension + ' measurments ' + $fileIndexCounter + ' .txt'
      if (-not($global:directory -match ".\\$"))
      {
        $global:directory = $global:directory+'\'
      }
      $global:measurmentFilePath = $global:directory+$measurmentfilename
      Write-Host "File exists. Checking next file."
    } else
    {
      Write-Host "File does not exist Creating new file"
      Add-Content -Path $global:measurmentFilePath -Value $finalMeasurment
      write-host "File created: $global:measurmentFilePath"
      break
    }
  }
  $global:e++
  if ($global:e -eq 4)
  {
    finalResult
  }
}


Function Opendatafile
{
  write-host 'Open data location'+ $global:directory
  start-process explorer.exe "$global:directory"
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
function finalResult
{
  # Get all measurement files from directory and sort them in required order
  $directoryString = [string]$global:directory
  $measurementFiles = @(
    Get-ChildItem $directoryString -Recurse -File | Where-Object { $_.Name -match "off" -and $_.Name -match "measurments" }
    Get-ChildItem $directoryString -Recurse -File | Where-Object { $_.Name -match "short idle" -and $_.Name -match "measurments" }
    Get-ChildItem $directoryString -Recurse -File | Where-Object { $_.Name -match "long idle" -and $_.Name -match "measurments" }
    Get-ChildItem $directoryString -Recurse -File | Where-Object { $_.Name -match "sleep" -and $_.Name -match "measurments" }
  )
  Write-Host "Directory being searched: $global:directory"
  Write-Host "Files found:"
  $measurementFiles | ForEach-Object { Write-Host $_.FullName }
    
  # Verify we have all required files
  $expectedFiles = @('off', 'short idle', 'long idle', 'sleep')
  for ($i = 0; $i -lt 4; $i++)
  {
    if ($null -eq $measurementFiles[$i])
    {
      Write-Host "Error: Missing $($expectedFiles[$i]) measurement file"
      $txtbox.AppendText("`r`nError: Missing $($expectedFiles[$i]) measurement file")
      return
    }
  }

  # Init Variables
  $testResultfilename = 'testResults.txt'
  if (-not($global:directory -match ".\\$"))
  {
    $global:directory = $global:directory+'\'
  }
  $global:testResultFilePath = $global:directory+$testResultfilename
  $global:averages = New-Object double[] 4  # Initialize array with 4 elements
  $measurementIndex = 0
    
  # Delete existing test results file if it exists
  if (test-path $global:testResultFilePath)
  {
    remove-item $global:testResultFilePath
  }

  # Process each measurement file in order
  foreach ($file in $measurementFiles)
  {
    write-host "Working on file: $($file.FullName)"
    $content = Get-Content $file.FullName
    foreach ($line in $content)
    {
      if ($line -match "Average:\s*(\d+\.?\d*)")
      {
        $global:averages[$measurementIndex] = [double]$matches[1]
        break
      }
    }
    $fileName = $file.Name -replace '.txt', ''
    $finalResultFile = $fileName + " : " + $global:averages[$measurementIndex]
    add-content -path $global:testResultFilePath -value $finalResultFile
    $measurementIndex++
  }
  write-host "Path to final result file: $global:testResultFilePath"

  # Write out the averages to the console
  write-host "Averages: $($global:averages[0]) $($global:averages[1]) $($global:averages[2]) $($global:averages[3])"
  $totalAverage = ($global:averages | Measure-Object -Average).Average
  write-host "Total average: $totalAverage"

  # Add averages in specified order at top of file
  $averagesLine = "$($global:averages[0])`t$($global:averages[3])`t$($global:averages[2])`t$($global:averages[1])"
  Set-Content -Path $global:testResultFilePath -Value $averagesLine
    
  # Add the rest of the content
  foreach ($file in $measurementFiles)
  {
    $fileName = $file.Name -replace '.txt', ''
    $index = [array]::IndexOf($measurementFiles, $file)
    $finalResultFile = $fileName + " : " + $global:averages[$index]
    Add-Content -Path $global:testResultFilePath -Value $finalResultFile
  }

  $totalAnnualEnergy = totalAnnualEnergyFormula $global:averages[0] $global:averages[1] $global:averages[2] $global:averages[3]
  add-content -path $global:testResultFilePath -value "`nTotal Annual Energy Consumption: $totalAnnualEnergy"
    
  # Replace "measurments" with "Average" in the test results file
  $content = Get-Content $global:testResultFilePath
  $content = $content -replace "measurments", "Average"
  Set-Content $global:testResultFilePath -Value $content

  # Move all .log files to data directory
  Get-ChildItem -Path $global:directory -Filter "*.log" | ForEach-Object {
    $destinationPath = Join-Path $global:dataDir $_.Name
    Move-Item -Path $_.FullName -Destination $destinationPath -Force
    Write-Host "Moved log file: $($_.Name) to data directory"
  }

  # Move measurement files to data directory
  Get-ChildItem -Path $global:directory -Filter "*measurments*.txt" | ForEach-Object {
    $destinationPath = Join-Path $global:dataDir $_.Name 
    Move-Item -Path $_.FullName -Destination $destinationPath -Force
    Write-Host "Moved measurement file: $($_.Name) to data directory"
  }

  if ($global:directory -and $global:testResultFilePath)
  {
    if (test-path $global:testResultFilePath)
    {
      start-process explorer.exe "$global:testResultFilePath"
    } else
    {
      Write-Host "Warning: Test result file does not exist"
    }
  }
  write-host "Total Annual Energy Consumption: $totalAnnualEnergy"
}

function totalAnnualEnergyFormula($value1, $value2, $value3, $value4)
{
  try
  {
    # Validate inputs are numbers and not null
    if ($null -eq $value1 -or $null -eq $value2 -or $null -eq $value3 -or $null -eq $value4)
    {
      throw "One or more input values are null"
    }
        
    if (-not ($value1 -is [ValueType]) -or -not ($value2 -is [ValueType]) -or 
      -not ($value3 -is [ValueType]) -or -not ($value4 -is [ValueType]))
    {
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
  } catch
  {
    write-host "Error in totalAnnualEnergyFormula: $($_.Exception.Message)" -ForegroundColor Red
    return $null
  }
}
#Hide-powershell
#HideConsole
ShowConsole
#Create a form

add-type -AssemblyName system.windows.forms

$form = New-Object windows.forms.form
$form.FormBorderStyle = "fixedtoolWindow"
$form.Text = "Meter GUI Window V4"
$form.StartPosition = "CenterScreen"
$form.Width = 520; $form.Height = 415

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
$opendatafilebutton.text = "open $($global:directory)"
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
$label1.Top =10; $label1.left = 20; $label1.width = 500;$label1.Height = 37
$label1.Text = "File Selected to Process: None Yet"
$label1.Font = New-Object System.Drawing.Font($label1.Font.FontFamily, 10)

#$label1.BackColor = "blue"
$label2 = New-Object System.Windows.Forms.Label
$label2.Top = 45; $label2.Left = 20; $label2.Width = 500; $label2.Height = 37
$label2.Text = "Data File Created: None Yet"
$label2.Font = New-Object System.Drawing.Font($label2.Font.FontFamily, 10)
$form.Controls.Add($label1) ;$form.controls.add($label2)


$form.Activate()
$result = $form.ShowDialog()
