# UPS-STATUS
Powershell script logging status of the Uninterruptible Power Supply (UPS) to screen and (if enabled) to a file. 
# How it works?
Script uses Powershell **Get-CimInstance** cmdlet to read class **Win32_Battery** from namespace **root\CIMV2**. 
It display informations like below (was used UPS APC Back-UPS RS 500):
```powershell
-- Basic informations
Name: Back-UPS RS 500 FW:30.j5.I USB FW:j5
Chemistry: Lead Acid
-- measurements started
date       time     Availability BatteryStatus EstimatedChargeRemaining EstimatedRunTime
----       ----     ------------ ------------- ------------------------ ----------------
09.08.2019 20:58:40            2             2                       98              203
09.08.2019 20:58:50            2             2                       98              203
09.08.2019 20:59:00            2             2                       98              203
09.08.2019 20:59:11            2             2                       98              203
09.08.2019 20:59:21            2             2                       98              203
09.08.2019 20:59:31            2             2                       98              203
09.08.2019 20:59:41            2             2                       98              203
-- Measurements completed
```
Where individual columns mean:
### Availability
1. = Other
2. = Unknown
3. = Running/Full Power
4. = Warning 
5. = In Test 
6. = Not Applicable
7. = Power Off
8. = Off Line
9. = Off Duty
10. = Degraded
11. = Not Installed
12. = Install Error
13. = Power Save - Unknown
14. = Power Save - Low Power Mode
15. = Power Save - Standby
16. = Power Cycle
17. = Power Save - Warning
18. = Paused
19. = Not Ready
20. = Not Configured
21. = Quiesced
###  BatteryStatus
1. =Other
2. = Unknown
3. = Fully Charged
4. = Low
5. = Critical
6. = Charging
7. = Charging and High
8. = Charging and Low
9. = Charging and Critical
10. = Undefined
11. = Partially Charged
### EstimatedChargeRemaining
This parameter shows the percentage of battery charge (0-100%)
### EstimatedRunTime
Calculated UPS runtime on battery during current load.
# How to use this script?
Run script file from powershell by typing:
```powershell
.\ups-status.ps1
```
Script will ask you about 3 questions:
1. How long test should be running (min.)? - if you think that given time is greater than than UPS can hold, please consider enable logging data to a file. In other case all data will be lost, when UPS will send signall to turn off the computer)
2. should data be logged to a file (y/n)? - if YES, file **log.csv** will be created in directory where this script is stored
3. Interval of reading information from UPS (sec.)

If UPS is connected and it is avaiable through **Win32_Battery** in namespace **root\CIMV2**, script will run displaying data on the screen and if was set, logging it to file.

If UPS is not avaiable through class **Win32_Battery** in namespace **root\CIMV2** it will display warning and exit.
> Can't find any connected UPS. Exiting.
