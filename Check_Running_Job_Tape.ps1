#By @wetcoriginal for VBR Backup to Tape
#Remember to edit the backup name line 7

Add-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue

$EstRun = get-date
$Jobs = Get-VBRTapeJob -Name 'Backup2Tape'
$Job = $null
$lastStatus = $Jobs | Foreach-Object LastResult
$lastState = $Jobs | Foreach-Object LastState
$LastRunSession=Get-VBRTapeBackupSession -Job $Jobs | Sort-Object -Property EndTime -Descending | Select-Object -First 1 -ExpandProperty EndTime
$LastRun=Get-VBRTapeBackupSession -Job $Jobs | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 -ExpandProperty CreationTime
$DiffTime=$EstRun - $LastRun

function CheckOneJob {
    if(($lastState -eq "Working") -and ($DiffTime.TotalHours -gt 24))
    {
        $global:CriticalCount++
        $global:OutMessageTemp += "CRITICAL - The job '" + $Jobs.Name + "' has been running for more than 24 hours`r`n"
        $global:ExitCode=2
        if($global:ExitCode -ne 2) {$global:ExitCode = 1}
    }
    elseif (($lastState -eq "Working") -and ($DiffTime.TotalHours -lt 24))
    {
         $global:OutMessageTemp += "OK - The job '" + $Jobs.Name + "' is in progress since " + $DiffTime.Hours + " hours`r`n"
         $global:OkCount++
    }
    else {
         $global:OutMessageTemp += "OK - The job '" + $Jobs.Name + "' is not currently running. `r`n"
         $global:OkCount++
    }
}

######################################################
#           Main loop (well, not exactly a loop)     #
######################################################
 
$nextIsJob=$false
$oneJob=$false
$jobToCheck=""
$WrongParam=$false
$DisabledJobs=$true
$global:OutMessageTemp=""
$global:OutMessage=""
$global:Exitcode=""
$WarningPreference = 'SilentlyContinue'
 
$VJobList=get-vbrjob
$ExitCode=0
 
IF($oneJob -eq $true){
    CheckOneJob($jobToCheck)}
else {
    foreach($Vjob in $VJobList){
        CheckOneJob($Vjob.Name)
    }
}

#Ajout de variables pour compter le nombre d'erreurs
$global:WarningDisabledCount=0
$global:WarningCount=0
$global:CriticalCount=0
$global:OkCount=0
$TotalCount=0
$global:Graph=""

$TotalCount=$global:WarningDisabledCount + $global:WarningCount + $global:CriticalCount + $global:OkCount
$global:OutMessage="TOTAL=>" + $TotalCount + " / OK=>" + $global:OkCount + " / CRITICAL=>" + $global:CriticalCount + " / DISABLE=>" + $global:WarningDisabledCount + " / WARNING=>" + $global:WarningCount
#Ajout variable Graph pour visualisation graphique sur centreon
$global:Graph=" |  Ok=" + $global:OkCount + " Warning=" + $global:WarningCount + " Critical=" + $global:CriticalCount

write-host $global:OutMessageTemp
write-host $global:OutMessage
exit $global:Exitcode
