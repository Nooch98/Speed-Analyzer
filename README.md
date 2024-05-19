# Speed-Analyzer
Speed ​​Analyzer is a PowerShell script created to control the speed of your connection by creating a task scheduled every hour and running automatically

## INSTAllATION
Speed-Anlyzer is recommended to be installed in the Scripts folder in the PowerShell 7 directory

1. Download the two scripts

```PowerShell
wget -P $env:USERPROFILE\Documents\PowerShell\Scripts\ https://raw.githubusercontent.com/Nooch98/Speed-Analyzer/main/speed_analyzer.ps1
```

```PowerShell
wget -P $env:USERPROFILE\Documents\PowerShell\Scripts\ https://raw.githubusercontent.com/Nooch98/Speed-Analyzer/main/speed_analyzer_uninstall.ps1
```

2. Execute speed_Analyzer.ps1

```PowerShell
& $env:USERPROFILE\Documents\PowerShell\Scripts\.\speed_analyzer.ps1
```

## FUNCTION
1. The script checks that the speedtest by ookla cli is installed
2. If it is not installed, check that chocolatey is installed
3. If the choco command exists install speedtest if choco does not exist install chocolatey also
4. Once both are installed. It will be executed checking if the Speed ​​Tracker task is already created in the Windows Task Scheduler.
5. If it is not created, it will create it and show us a window to configure how often we want the automated task to be executed.

![Captura de pantalla 2024-05-19 194053](https://github.com/Nooch98/Speed-Analyzer/assets/73700510/e1f69a84-6fba-4fd2-a56e-1e736fa698ec)

6. Now it will create the scheduled task with our settings and start measuring the speed.
7. Once it has measured the speed, it will record it in the same Scrips folder in a csv file and if it is lower than the defined speed, a pop-up window will appear warning us.

!!! To change the minimum speeds that the test has to meet before notifying us, you just have to change the numbers on the following line

![Captura de pantalla 2024-05-19 194533](https://github.com/Nooch98/Speed-Analyzer/assets/73700510/ca147517-bac3-4c0e-b166-4c85dfd30f57)

