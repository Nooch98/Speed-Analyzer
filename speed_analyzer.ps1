Add-Type -AssemblyName System.Windows.Forms

$taskName = "Speed tracker"
$scriptPath = "$HOME\Desktop\Pruebas\Speed-Analyzer\"
$markerFile = "$scriptPath\installation_complete.marker"

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

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (!$existingTask) {
    # Definir la acción a realizar por la tarea (ejecutar el script)
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -WindowStyle Hidden -File "$HOME\Documents\PowerShell\Scripts\speed_analyzer.bat"'
    # Definir la frecuencia de ejecución de la tarea (cada 1 hora, repetir durante 10 años)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 3650)  # 10 años

    # Crear la tarea programada
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Tarea programada para ejecutar el script de Speedtest cada hora."
        
    Write-Host "Se ha creado la tarea programada '$taskName'."
    } else {
        Write-Host "La tarea programada '$taskName' ya existe."
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
    } else {
        Write-Host "La velocidad de Internet es aceptable."
    }
} else {
    Write-Host "No se pudo extraer la velocidad de descarga y subida de la salida de Speedtest."
}
