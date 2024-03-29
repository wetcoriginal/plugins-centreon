#Edited by @wetcoriginal for Veeam Backup Office 365#

function CheckOneJob {
$JobCheck=Get-VBOJob -Name $args[0]
$lastStatus=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.Status}
$CreationJobTime=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.CreationTime}
$DisabledJobs=$JobCheck | Foreach-Object {$_.IsEnabled}
$Avant=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.CreationTime}
$Apres=Get-Date
$TempsEcoulee=$Apres-$Avant
$LimitTemps="23:59:59.0000000"
 
if($global:OutMessageTemp -ne ""){$global:OutMessageTemp+="`r`n"}
if($JobCheck.isEnabled -eq $false){ # Disabled job -> WARNING
if($DisabledJobs -ne $true){
$global:OutMessageTemp+="WARNING - Le job '"+$JobCheck.Name+"' est desactive "
$global:WarningDisabledCount++ #exo
if($global:ExitCode -lt 2){$global:ExitCode=1} # if no previous Critical status then switch to WARNING
}
}
else # The job is enabled
{
if($lastStatus -eq "Running" -and $TempsEcoulee -gt $LimitTemps){
$global:OutMessageTemp+="WARNING: Le job "+$JobCheck.Name+" est en cours depuis $TempsEcoulee minutes"
$global:WarningCount++ #exo
}
elseif($lastStatus -eq "Running"){
$global:OutMessageTemp+="OK - Le job "+$JobCheck.Name+" est en cours de sauvegarde"
$global:OkCount++ #exo
}
else {
if($lastStatus -ne "Success"){ # Failed or None->never run before (probaly a newly created job)
if($lastStatus -eq "none"){
$global:OutMessageTemp+="WARNING: Le job "+$JobCheck.Name+" n a jamais ete execute"
$global:WarningCount++ #exo
if($global:ExitCode -ne 2) {$global:ExitCode=1}
}
elseif($lastStatus -eq "Warning"){
$global:OutMessageTemp+="WARNING - Le job "+$JobCheck.Name+" s est termine avec des messages d'alertes"
$global:WarningCount++ #exo
if($global:ExitCode -ne 2) {$global:ExitCode=1}
}
else {
$global:OutMessageTemp+="CRITICAL - Le job "+$JobCheck.Name+" a echoue"
$global:CriticalCount++ #exo
$global:ExitCode=2
}
}
else
{
 
if (($JobCheck.IsBackup -eq $true) -and ($DiffTime.TotalDays -gt 1))
{
$global:ExitCode=2
$global:OutMessageTemp+="CRITICAL - Le job "+$JobCheck.Name+" n a pas ete execute lors de la derniere journee"
$global:CriticalCount++ #exo
}
 
else
{
if(($JobCheck.IsReplica -eq $true) -and ($DiffTime.TotalHours -gt 2) )
{
$global:ExitCode=2
$global:OutMessageTemp+="CRITICAL - La replication "+$JobCheck.Name+" n a pas ete execute lors de la derniere journee"
$global:CriticalCount++ #exo
}
else
{
$global:OutMessageTemp+="OK - "
$global:OutMessageTemp+=$JobCheck.Name+" "
$global:OutMessageTemp+="execute avec succes le $CreationJobTime"
$global:OkCount++ #exo
}
}
}
}
}
}
 
######################################################
# Main loop (well, not exactly a loop) #
######################################################
 
$nextIsJob=$false
$oneJob=$false
$jobToCheck=""
$WrongParam=$false
$global:OutMessageTemp=""
$global:OutMessage=""
$global:Exitcode=""
#exo - Ajout de variables pour compter le nombre d'erreurs
$global:WarningDisabledCount=0
$global:WarningCount=0
$global:CriticalCount=0
$global:OkCount=0
$TotalCount=0
 
 
if( $args.Length -ge 1)
{
foreach($value in $args) {
if($nextIsJob -eq $true) { # parameter coming after -j switch
if(($value.Length -eq 2) -and ($value.substring(0,1) -eq '-')){
$WrongParam=$true
}
$nextIsJob=$false
$jobToCheck=$value
$onejob=$true
}
elseif($value -eq '-j') { # -j -> check only one job and its name goes in the following parameter (default is to check all backup jobs)
$nextIsJob=$true
}
elseif($value -eq '-d') { # -d -> Do not warn for disabled jobs (default is to warn)
$DisabledJobs=$false
}
else {$WrongParam=$true}
}
}
if($WrongParam -eq $true){
write-host "Wrong parameters"
write-host "Syntax: Check_Veeam_Jobs [-j JobNameToCheck] [-d]"
write-host " -j switch to check only one job (default is to check all backup jobs)"
Write-Host " -d switch to not inform when there is any disabled job"
exit 1
}
$VJobList=Get-VBOJob
$ExitCode=0
IF($oneJob -eq $true){
CheckOneJob($jobToCheck)}
else {
foreach($Vjob in $VJobList){
CheckOneJob($Vjob.Name)
}
}
#exo - Ajout du nombre total d'erreur détectées
$TotalCount=$global:WarningDisabledCount + $global:WarningCount + $global:CriticalCount + $global:OkCount
$global:OutMessage="TOTAL=>" + $TotalCount + " / OK=>" + $global:OkCount + " / CRITICAL=>" + $global:CriticalCount + " / DISABLE=>" + $global:WarningDisabledCount + " / WARNING=>" + $global:WarningCount
$global:OutMessage+="`r`n" + $global:OutMessageTemp

if($global:WarningCount -ne 0){
$global:Exitcode = 1
}
elseif($global:WarningDisabledCount -ne 0){
$global:Exitcode = 1
}
elseif($global:CriticalCount -ne 0){
$global:Exitcode = 2
}
else{
$global:Exitcode = 0
}

write-host $global:OutMessage
exit $global:Exitcode
