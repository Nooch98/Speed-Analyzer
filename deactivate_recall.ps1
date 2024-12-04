# Verify if the script is executing by admin
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "This script requires admin privileges" -ForegroundColor Red
}

$check_recall = DISM /Online /Get-FeatureInfo /FeatureName:Recall

$stateline = $check_recall | Select-String -Pattern "State|Estado" | ForEach-Object { $_.ToString().split(":")[-1].Trim() }

function disable {
    if ($stateline -eq "Enable" -or $stateline -eq "Habilitado") {
        Write-Host "Disabling Recall..." -ForegroundColor Blue
        DISM /online /disable-feature /FeatureName=Recall /NoRestart
        Write-Host "Recall was disabled." -ForegroundColor Green
    } else {
        Write-Host "Recall is already disabled." -ForegroundColor Green
    }
}

function enable {
    if ($stateline -eq "Disable" -or $stateline -eq "Deshabilitado") {
        Write-Host "Enabling Recall..." -ForegroundColor Blue
        DISM /online /enable-feature /FeatureName=Recall /NoRestart
        Write-Host "Recall was enabled." -ForegroundColor Green
    } else {
        Write-Host "Recall is already enabled." -ForegroundColor Green
    }
}

function check {
    Write-Host "Checking Recall state..." -ForegroundColor Cyan
    if ($stateline) {
        Write-Host "Recall State: $stateline" -ForegroundColor Green
    } else {
        Write-Host "Recall state could not be determined." -ForegroundColor Red
    }
}


Write-Host "---- OPTIONS ----" -ForegroundColor Cyan
Write-Host "1. Check Recall." -ForegroundColor yellow
Write-Host "2. Disable Recall." -ForegroundColor yellow
Write-Host "3. Enable Recall." -ForegroundColor yellow
Write-Host "4. Exit" -ForegroundColor yellow

$quest = Read-Host "What do you want to do?"

switch ($quest) {
    "1" { check }
    "2" { disable }
    "3" { enable }
    "4" { Write-Host "Exiting script." -ForegroundColor Cyan; exit }
    default { Write-Host "Invalid option. Please choose a valid option." -ForegroundColor Red }
}
