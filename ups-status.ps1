[CmdletBinding()]
param()

<################################## -VARIABLES- #####################################>
$log_file = "$PsScriptRoot\log.csv" # the name and path of the log file. Deafult is the path withing script directory with name "log.csv"
$log_data = $null # variable that stores information about the selection of the user about whether the script should log data to the file or not

<################################## -FUNCTIONS- #####################################>
function log_to_file ($content){
 
    if ($(($log_data -eq "y") -or ($log_data -eq "yes"))){
        Write-Verbose "Funkcja 'log_to_file' zapisuje dane do pliku"
        Add-Content $log_file $content
    }
    else {Write-Verbose "Zmienna log_data ma wartosc $log_data, a wiec funkcja 'log_to_file' nie zapisuje danych do pliku"}
}

<################################## -QUESTIONS- #####################################>
$dlugosc_pomiaru = Read-host -Prompt "- How long test should be running (min.)? - if you think that given time is greater than than UPS can hold, please consider enable logging data to a file. In other case all data will be lost, when UPS will send signall to turn off the computer)"
$dlugosc_pomiaru = new-timespan -Minutes $dlugosc_pomiaru

<### -SHOULD DATA BE LOGGED TO A FILE?- ###>
DO
{
    $log_data = Read-Host -Prompt "- Should data be logged to a file (y/n)? - if YES, file will be created in directory where this script is stored"
    if ($($log_data -ne "y") -and $($log_data -ne "yes") -and $($log_data -ne "n") -and $($log_data -ne "no")){
        Write-Warning -Message "'$log_data' is not valid option. Please choose (y/n)";
    }
} until ($($log_data -eq "y") -or $($log_data -eq "yes") -or $($log_data -eq "n") -or $($log_data -eq "no"))

switch ($log_data)
{
    {($_ -eq "y") -or ($_ -eq "yes")} {
        if (!(Test-Path $log_file)){
                New-Item -path $log_file -ItemType "file"
                Write-Information "New file was created in: $log_file" -InformationAction Continue
            }
        else {Write-Information "Logging enabled to file $log_file" -InformationAction Continue}
        }
    {($_ -eq "n") -or ($_ -eq "no")} {Write-Information "Logging disabled" -InformationAction Continue} 
}

$reading_interval = Read-host -Prompt "- Interval of reading information from UPS (sec.)"


<######################### -CHECKING IF UPS IS CONNECTED - #########################>
$ups_present = Get-CimInstance -ClassName 'Win32_Battery' -Namespace 'root\cimv2';
if ($ups_present -eq $null){
    write-warning "Can't find any connected UPS. Exiting."
}
else {
    <########################## -BASIC INFORMATIONS ABOUT UPS- ##########################>
    Write-Host "`r`n-- Basic informations"
    ######Write-Host"-- Basic informations" 
    log_to_file ("-- Basic informations")

    Write-Host "Name: $(Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty Name)"
    #######Write-Host"Name: $(Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty Name)" 
    log_to_file ("Name: $(Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty Name)")

    $chemistry = switch (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "Chemistry")
        {
            1 {Write-Host "Chemistry: Other" 
                log_to_file ("Chemistry: Other")}
            2 {Write-Host "Chemistry: Unknown"
                log_to_file ("Chemistry: Unknown")}
            3 {Write-Host "Chemistry: Lead Acid"
                log_to_file ("Chemistry: Lead Acid")}
            4 {Write-Host "Chemistry: Nickel Cadmium" 
                log_to_file ("Chemistry: Nickel Cadmium")}
            5 {Write-Host "Chemistry: Nickel Metal Hydride"
                log_to_file ("Chemistry: Nickel Metal Hydride")}
            6 {Write-Host "Chemistry: Lithium-ion"
                log_to_file ("Chemistry: Lithium-ion")}
            7 {Write-Host "Chemistry: Zinc air"
                log_to_file ("Chemistry: Zinc air")}
            8 {Write-Host "Chemistry: Lithium Polymer"
                log_to_file ("Chemistry: Lithium Polymer")}
            default {Write-Warning -Message "Can not determine the type of battery (Chemistry parameter)"
                log_to_file ("Can not determine the type of battery (Chemistry parameter)")}
        }
    
    <########################### TABLE WITH MEASURED UPS VALUES ###########################>
    Write-Host "-- measurements started"
    log_to_file ("-- measurements started")
    
    # Tworzę obiekt, który będzie przechowywał parametry UPSa
    $obiekt = New-Object psobject -Property @{
        date = Get-Date -Format "dd.MM.yyyy"
        time = Get-Date -Format "HH:mm:ss"
        Availability = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "Availability")
        BatteryStatus = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "BatteryStatus")
        EstimatedChargeRemaining = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "EstimatedChargeRemaining")
        EstimatedRunTime = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "EstimatedRunTime")
    };

    #wyświetlam obiekt pipeując go przez format tabeli oraz funkcję trim dzięki czemu usuwane są puste wiersze przed danymi i po nich. Po prostu tabelka się ładniej wyświetla
    ($obiekt | Format-Table -Property date, time, Availability, BatteryStatus, EstimatedChargeRemaining, EstimatedRunTime | Out-String).Trim();
    log_to_file ("date`ttime`tAvailability`tBatteryStatus`tEstimatedChargeRemaining`tEstimatedRunTime")
    log_to_file ($((($obiekt.date + "`t" +  $obiekt.time + "`t" + $obiekt.Availability + "`t" + $obiekt.BatteryStatus + "`t" + $obiekt.EstimatedChargeRemaining + "`t" + $obiekt.EstimatedRunTime | Out-String).Trim())))


    start-sleep -seconds $reading_interval

    $sw = [diagnostics.stopwatch]::StartNew()

    while ($sw.elapsed -lt $dlugosc_pomiaru){
        $obiekt.date = Get-Date -Format "dd.MM.yyyy"
        $obiekt.time = Get-Date -Format "HH:mm:ss"
        $obiekt.Availability = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "Availability")
        $obiekt.BatteryStatus = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "BatteryStatus")
        $obiekt.EstimatedChargeRemaining = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "EstimatedChargeRemaining")

        $Current_EstimatedRunTime = (Get-CimInstance -ClassName Win32_Battery -Namespace root\CIMV2 | Select-Object -ExpandProperty "EstimatedRunTime")
        if (($Current_EstimatedRunTime) -eq 71582788) {
            $Current_EstimatedRunTime = "AC powered"
            $obiekt.EstimatedRunTime = $Current_EstimatedRunTime
        }
        else {
            $obiekt.EstimatedRunTime = $Current_EstimatedRunTime
        }   
        
        #wyświetlam utworzony obiekt przepuszczając go przez formatowanie tabeli oraz powstały strin puszczam do funkcji TRIM w celu usunięcia pustych wierszy
        ($obiekt | Format-Table -HideTableHeaders -Property date, time,  Availability, BatteryStatus, EstimatedChargeRemaining, EstimatedRunTime | Out-String).Trim();
        log_to_file ($((($obiekt.date + "`t" +  $obiekt.time + "`t" + $obiekt.Availability + "`t" + $obiekt.BatteryStatus + "`t" + $obiekt.EstimatedChargeRemaining + "`t" + $obiekt.EstimatedRunTime | Out-String).Trim())))

        #tutaj ustawia się jaka ma być przerwa pomiędzy pomiarami
        start-sleep -seconds $reading_interval
    }

    Write-Host "-- Measurements completed"
    log_to_file ("-- Measurements completed")
}