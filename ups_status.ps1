$computer = '.'
$dlugosc_pomiaru = Read-host -Prompt "- podaj długość testu w minutach"
$dlugosc_pomiaru = new-timespan -Minutes $dlugosc_pomiaru 
$interwal_odczytow = Read-host -Prompt "- podaj interwał odczytywania informacji w sekundach" 

<########################### BASIC INFORMATIONS ABOUT UPS ###########################>
Write-Host "Name: " (Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "Name") -ForegroundColor Green

$chemistry = switch (Get-WmiObject -Class Win32_Battery -Namespace root\CIMV2 | select -ExpandProperty "Chemistry")
    {
        1 {Write-Host "Chemistry: Other"}
        2 {Write-Host "Chemistry: Unknown"}
        3 {Write-Host "Chemistry: Lead Acid" -ForegroundColor Green}
        4 {Write-Host "Chemistry: Nickel Cadmium"}
        5 {Write-Host "Chemistry: Nickel Metal Hydride"}
        6 {Write-Host "Chemistry: Lithium-ion"}
        7 {Write-Host "Chemistry: Zinc air"}
        8 {Write-Host "Chemistry: Lithium Polymer"}
        default {Write-Host "Chemistry: can not determine the type of battery" -ForegroundColor Red}
    }




<########################### TABLE WITH MEASURED UPS VALUES ###########################>
# to jest chyba tablica
$ups = @{
    data = Get-Date -Format "dd.MM.yyyy"
    godzina = Get-Date -Format "HH:mm:ss"
    Availability = (Get-WmiObject -Class Win32_Battery -ComputerName $computer -Namespace root\CIMV2 | select -ExpandProperty "Availability")
    BatteryStatus = (Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "BatteryStatus" ) 
    EstimatedChargeRemaining = (Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "EstimatedChargeRemaining" ) 
    EstimatedRunTime = (Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "EstimatedRunTime")
    
}

# z powyższej tablicy tworzę obiekt, który będzie przechowywał parametry UPSa
$obiekt = New-Object psobject -Property $ups; 

#wyświetlam obiekt pipeując go przez format tabeli oraz funkcję trim dzięki czemu usuwane są puste wiersze przed danymi i po nich. Po prostu tabelka się ładniej wyświetla
($obiekt | Format-Table -Property Data, Godzina, Availability, BatteryStatus, EstimatedChargeRemaining, EstimatedRunTime | Out-String).Trim() ;
start-sleep -seconds $interwal_odczytow

$sw = [diagnostics.stopwatch]::StartNew()

while ($sw.elapsed -lt $dlugosc_pomiaru){
    $obiekt.data = Get-Date -Format "dd.MM.yyyy"
    $obiekt.godzina = Get-Date -Format "HH:mm:ss"
    $obiekt.Availability = Get-WmiObject -Class Win32_Battery -ComputerName $computer -Namespace root\CIMV2 | select -ExpandProperty "Availability"
    $obiekt.BatteryStatus = (Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "BatteryStatus" ) 
    
    $obiekt.EstimatedChargeRemaining = Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "EstimatedChargeRemaining"
    
    $Current_EstimatedRunTime = Get-WmiObject -class Win32_Battery -ComputerName $computer -NameSpace root\CIMV2 | select -ExpandProperty "EstimatedRunTime"
    if (($Current_EstimatedRunTime) -eq 71582788) {
        $Current_EstimatedRunTime = "AC powered"
        $obiekt.EstimatedRunTime = $Current_EstimatedRunTime
    }
    else {
        $obiekt.EstimatedRunTime = $Current_EstimatedRunTime
    }
    

    
    

    #wyświetlam utworzony obiekt przepuszczając go przez formatowanie tabeli oraz powstały strin puszczam do funkcji TRIM w celu usunięcia pustych wierszy
    ($obiekt | Format-Table -HideTableHeaders -Property Data, Godzina,  Availability, BatteryStatus, EstimatedChargeRemaining, EstimatedRunTime | Out-String).Trim() ;
     
    #tutaj ustawia się jaka ma być przerwa pomiędzy pomiarami
    start-sleep -seconds $interwal_odczytow
}

Write-Host "- measurement completed"