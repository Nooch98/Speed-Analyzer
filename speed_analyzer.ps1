Add-Type -AssemblyName System.Windows.Forms

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