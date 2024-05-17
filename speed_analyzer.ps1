Add-Type -AssemblyName System.Windows.Forms

$taskName = "Speed tracker"
$scriptPath = "$HOME\Documents\PowerShell\Scripts\"
$markerFile = "$scriptPath\installation_complete.marker"
$speedTestResultsPath = "$scriptPath\speedtest_results.csv"

# Verificar si la instalación ya se ha completado
if (Test-Path $markerFile) {
    Write-Host "La instalación ya se ha completado."
} else {
    $existingSpeedTest = Get-Command -Name speedtest -ErrorAction SilentlyContinue

    if ($existingSpeedTest -eq $null) {
        Write-Host "El comando 'speedtest' no está instalado."

        # Verifica si choco está instalado
        $existingchoco = Get-Command -Name choco -ErrorAction SilentlyContinue

        if ($existingchoco -eq $null) {
            Write-Host "Instalando choco..."
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "choco instalado correctamente."
            
            # Instala SpeedTest usando choco
            Write-Host "Instalando SpeedTest..."
            choco install speedtest
            Write-Host "SpeedTest instalado correctamente."

            # Marcar la instalación como completa
            New-Item -ItemType File -Path $markerFile | Out-Null
        } else {
            # Instala SpeedTest usando choco
            Write-Host "Instalando SpeedTest..."
            choco install speedtest
            Write-Host "SpeedTest instalado correctamente."

            # Marcar la instalación como completa
            New-Item -ItemType File -Path $markerFile | Out-Null
        }
    } else {
        Write-Host "El comando 'speedtest' ya está instalado."
    }
}

function Show-CustomForm {
    $form = New-Object Windows.Forms.Form
    $form.Text = "Configuración de Tarea Programada"
    $form.Size = New-Object Drawing.Size(400, 250)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    $label1 = New-Object Windows.Forms.Label
    $label1.Text = "Intervalo de repetición (en horas):"
    $label1.AutoSize = $true
    $label1.Location = New-Object Drawing.Point(10, 20)
    $form.Controls.Add($label1)

    $textBox1 = New-Object Windows.Forms.TextBox
    $textBox1.Location = New-Object Drawing.Point(200, 20)
    $textBox1.Size = New-Object Drawing.Size(50, 20)
    $textBox1.Text = "1"
    $form.Controls.Add($textBox1)

    $label2 = New-Object Windows.Forms.Label
    $label2.Text = "Duración (en días):"
    $label2.AutoSize = $true
    $label2.Location = New-Object Drawing.Point(10, 60)
    $form.Controls.Add($label2)

    $textBox2 = New-Object Windows.Forms.TextBox
    $textBox2.Location = New-Object Drawing.Point(200, 60)
    $textBox2.Size = New-Object Drawing.Size(50, 20)
    $textBox2.Text = "3650"
    $form.Controls.Add($textBox2)

    $checkBox1 = New-Object Windows.Forms.CheckBox
    $checkBox1.Text = "Permitir que la tarea arranque el equipo"
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

        # Definir la acción a realizar por la tarea (ejecutar el script)
        $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -WindowStyle Hidden -File "$HOME\Documents\PowerShell\Scripts\speed_analyzer.ps1"'

        # Definir la frecuencia de ejecución de la tarea (cada N horas, repetir durante X días)
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours $interval) -RepetitionDuration (New-TimeSpan -Days $duration)

        # Crear la tarea programada
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        if ($wakeToRun) {
            $settings.WakeToRun = $true
        }

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Tarea programada para ejecutar el script de Speedtest."

        Write-Host "Se ha creado la tarea programada '$taskName' con los parámetros especificados."
    } else {
        Write-Host "No se ha creado ninguna tarea programada."
    }
} else {
    Write-Host "La tarea programada '$taskName' ya existe."
}

function Write-SpeedTestResult {
    param (
        [double]$downloadSpeed,
        [double]$uploadSpeed
    )

    $result = "{0},{1},{2}" -f (Get-Date).ToString("s"), $downloadSpeed, $uploadSpeed
    Add-Content -Path $speedTestResultsPath -Value $result
}

# Ejecutar Speedtest
$(speedtest)

# Obtener la velocidad de descarga y subida desde la salida de Speedtest
$speedtestOutput = speedtest | Out-String

# Obtener la velocidad de descarga y subida desde la salida de Speedtest
$downloadSpeedMatch = [regex]::Match($speedtestOutput, 'Download:\s+(\d+\.\d+) Mbps')
$uploadSpeedMatch = [regex]::Match($speedtestOutput, 'Upload:\s+(\d+\.\d+) Mbps')

# Verificar si se encontraron las velocidades de descarga y subida en la salida de Speedtest
if ($downloadSpeedMatch.Success -and $uploadSpeedMatch.Success) {
    $downloadSpeed = [double]$downloadSpeedMatch.Groups[1].Value
    $uploadSpeed = [double]$uploadSpeedMatch.Groups[1].Value

    # Establecer umbrales de velocidad
    $downloadThreshold = 900
    $uploadThreshold = 800

    # Comprobar si la velocidad es inferior al umbral
    if ($downloadSpeed -lt $downloadThreshold -or $uploadSpeed -lt $uploadThreshold) {
        # Mostrar ventana de advertencia
        $title = "Advertencia de velocidad de Internet"
        $message = "La velocidad de descarga es $downloadSpeed Mbps y la velocidad de subida es $uploadSpeed Mbps, lo que es inferior al umbral requerido."
        [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Write-SpeedTestResult
    } else {
        Write-Host "La velocidad de Internet es aceptable."
        Write-SpeedTestResult
    }
} else {
    Write-Host "No se pudo extraer la velocidad de descarga y subida de la salida de Speedtest."
}