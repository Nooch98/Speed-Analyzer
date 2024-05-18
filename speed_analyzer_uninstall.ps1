$taskName = "Speed tracker"
$scriptPath = "$env:USERPROFILE\Documents\PowerShell\Scripts\"
$markerFile = "$scriptPath\installation_complete.marker"
$speedTestResultsPath = "$scriptPath\speedtest_results.csv"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "La tarea programada '$taskName' ha sido eliminada."
} else {
    Write-Host "La tarea programada '$taskName' no existe."
}

if (Test-Path $markerFile) {
    Remove-Item -Path $markerFile -Force
    Write-Host "El archivo marcador de instalación ha sido eliminado."
}

if (Test-Path $speedTestResultsPath) {
    Remove-Item -Path $speedTestResultsPath -Force
    Write-Host "El archivo de resultados de speedtest ha sido eliminado."
}

$speedAnalyzerScript = "$scriptPath\speed_analyzer.ps1"
if (Test-Path $speedAnalyzerScript) {
    Remove-Item -Path $speedAnalyzerScript -Force
    Write-Host "El script speed_analyzer.ps1 ha sido eliminado."
}

