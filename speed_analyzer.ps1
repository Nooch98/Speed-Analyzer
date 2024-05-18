Add-Type -AssemblyName System.Windows.Forms

$taskName = "Speed tracker"
$scriptPath = "$env:USERPROFILE\Documents\PowerShell\Scripts\"
$markerFile = "$scriptPath\installation_complete.marker"
$speedTestResultsPath = "$scriptPath\speedtest_results.csv"

# Check if the installation is complete
if (Test-Path $markerFile) {
    Write-Host "The installation has already been completed."
} else {
    $existingSpeedTest = Get-Command -Name speedtest -ErrorAction SilentlyContinue

    if ($existingSpeedTest -eq $null) {
        Write-Host "The 'speedtest' command is not installed."

        # Check if choco is installed
        $existingchoco = Get-Command -Name choco -ErrorAction SilentlyContinue

        if ($existingchoco -eq $null) {
            Write-Host "Installing choco..."
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "choco installed successfully."
            
            # Install SpeedTest using choco
            Write-Host "Installing SpeedTest..."
            choco install speedtest
            Write-Host "SpeedTest installed successfully."

            # Mark the installation as complete
            New-Item -ItemType File -Path $markerFile | Out-Null
        } else {
            # Install SpeedTest using choco.
            Write-Host "Installing SpeedTest..."
            choco install speedtest
            Write-Host "SpeedTest installed successfully."

            # Mark installation as complete
            New-Item -ItemType File -Path $markerFile | Out-Null
        }
    } else {
        Write-Host "The 'speedtest' command is already installed."
    }
}

function Show-CustomForm {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Scheduled Task Configuration"
    $form.Size = New-Object Drawing.Size(400, 250)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    $label1 = New-Object Windows.Forms.Label
    $label1.Text = "Repetition Interval (in hours):"
    $label1.AutoSize = $true
    $label1.Location = New-Object Drawing.Point(10, 20)
    $form.Controls.Add($label1)

    $textBox1 = New-Object Windows.Forms.TextBox
    $textBox1.Location = New-Object Drawing.Point(200, 20)
    $textBox1.Size = New-Object Drawing.Size(50, 20)
    $textBox1.Text = "1"
    $form.Controls.Add($textBox1)

    $label2 = New-Object Windows.Forms.Label
    $label2.Text = "Duration (in days):"
    $label2.AutoSize = $true
    $label2.Location = New-Object Drawing.Point(10, 60)
    $form.Controls.Add($label2)

    $textBox2 = New-Object Windows.Forms.TextBox
    $textBox2.Location = New-Object Drawing.Point(200, 60)
    $textBox2.Size = New-Object Drawing.Size(50, 20)
    $textBox2.Text = "3650"
    $form.Controls.Add($textBox2)

    $checkBox1 = New-Object Windows.Forms.CheckBox
    $checkBox1.Text = "Allow task to wake the computer"
    $checkBox1.AutoSize = $true
    $checkBox1.Location = New-Object Drawing.Point(10, 100)
    $form.Controls.Add($checkBox1)

    $buttonOK = New-Object Windows.Forms.Button
    $buttonOK.Text = "OK"
    $buttonOK.Location = New-Object Drawing.Point(150, 150)
    $buttonOK.Size = New-Object Drawing.Size(75, 30)
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($buttonOK)

    $form.AcceptButton = $buttonOK

    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            Interval = [int]$textBox1.Text
            Duration = [int]$textBox2.Text
            WakeToRun = $checkBox1.Checked
        }
    } else {
        return $null
    }
}

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (!$existingTask) {
    $config = Show-CustomForm

    if ($config -ne $null) {
        $interval = $config.Interval
        $duration = $config.Duration
        $wakeToRun = $config.WakeToRun

        # Define the action to be performed by the task (execute the script)
        $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -WindowStyle Hidden -File "$env:USERPROFILE\Documents\PowerShell\Scripts\speed_analyzer.ps1"'

        # Define the frequency of task execution (every N hours, repeat for X days)
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours $interval) -RepetitionDuration (New-TimeSpan -Days $duration)

        # Create the scheduled task
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        if ($wakeToRun) {
            $settings.WakeToRun = $true
        }

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Scheduled task to run the Speedtest script."

        Write-Host "The scheduled task '$taskName' has been created with the specified parameters."
    } else {
        Write-Host "No scheduled task has been created."
    }
} else {
    Write-Host "The scheduled task '$taskName' already exists."
}

function Write-SpeedTestResult {
    param (
        [double]$downloadSpeed,
        [double]$uploadSpeed
    )

    $result = "{0},{1},{2}" -f (Get-Date).ToString("s"), $downloadSpeed, $uploadSpeed
    Add-Content -Path $speedTestResultsPath -Value $result
}

# Run Speedtest
$(speedtest)

# Get the download and upload speeds from the Speedtest output
$speedtestOutput = speedtest | Out-String

# Get the download and upload speeds from the Speedtest output
$downloadSpeedMatch = [regex]::Match($speedtestOutput, 'Download:\s+(\d+\.\d+) Mbps')
$uploadSpeedMatch = [regex]::Match($speedtestOutput, 'Upload:\s+(\d+\.\d+) Mbps')

# Check if the download and upload speeds were found in the Speedtest output
if ($downloadSpeedMatch.Success -and $uploadSpeedMatch.Success) {
    $downloadSpeed = [double]$downloadSpeedMatch.Groups[1].Value
    $uploadSpeed = [double]$uploadSpeedMatch.Groups[1].Value

    # Set speed thresholds
    $downloadThreshold = 900
    $uploadThreshold = 800

    # Check if the speed is below the threshold
    if ($downloadSpeed -lt $downloadThreshold -or $uploadSpeed -lt $uploadThreshold) {
        # Display warning window
        $title = "Internet Speed Warning"
        $message = "The download speed is $downloadSpeed Mbps and the upload speed is $uploadSpeed Mbps, which is below the required threshold."
        [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Write-SpeedTestResult -downloadSpeed $downloadSpeed -uploadSpeed $uploadSpeed
    } else {
        Write-Host "The internet speed is acceptable."
        Write-SpeedTestResult -downloadSpeed $downloadSpeed -uploadSpeed $uploadSpeed
    }
} else {
    Write-Host "Failed to extract download and upload speeds from Speedtest output."
}