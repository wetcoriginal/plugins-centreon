# by @wetcoriginal for VBR for multiple jobs

Add-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue
function CheckOneJob {
    $JobCheck=Get-VBOJob -Name $args[0]

        if($global:OutMessageTemp -ne ""){$global:OutMessageTemp+="`r`n"}
                    #$global:OutMessageTemp+="QUoiquece:"+$DiffTime.TotalDays
                    $EstRun=get-date
                    $LimitTemps="23:59:00.0000000"
                    if($lastStatus -eq "Running")
                    {
                        $LastRunSession=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.Status}
                        $LastRun=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.EndTime}
                        $DiffTime=$EstRun-$LastRun

                    }
                    else
                    {
                        $LastRun=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.EndTime}
                        $DiffTime=$EstRun-$LastRun
                    }
                    
                    
                    if($lastStatus -eq "Running" -and $DiffTime -gt $LimitTemps){
                    {
                        $global:ExitCode=2
                        $global:OutMessageTemp+="CRITICAL - The backup job " + $JobCheck.Name + " has been running for more than 24 hours`r`n"
                        $global:CriticalCount++
                    }
                    if($lastStatus -eq "Running" -and $DiffTime -lt $LimitTemps){
                    {
                        $global:OutMessageTemp+="OK - The backup job " + $JobCheck.Name + " is in progress since " + $DiffTime.Hours + " hours and " + $DiffTime.Minutes + " minutes `r`n"
                        $global:OkCount++
                    }
                        else
                        {
                            $global:OutMessageTemp+="OK - The "+$JobCheck.Name+" job is not running"
                            $global:OkCount++
                        }
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

#Ajout de variables pour compter le nombre d'erreurs
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
    write-host "       -j switch to check only one job (default is to check all backup jobs)"
    Write-Host "       -d switch to not inform when there is any disabled job"
    exit 1
    }

$VJobList=get-vbojob
$ExitCode=0

IF($oneJob -eq $true){
    CheckOneJob($jobToCheck)}
else {
    foreach($Vjob in $VJobList){
        CheckOneJob($Vjob.Name)
    }
}
#Ajout du nombre total d'erreur dÃ©tectÃ©es
$TotalCount=$global:WarningDisabledCount + $global:WarningCount + $global:CriticalCount + $global:OkCount
$global:OutMessage="TOTAL=>" + $TotalCount + " / OK=>" + $global:OkCount + " / CRITICAL=>" + $global:CriticalCount + " / DISABLE=>" + $global:WarningDisabledCount + " / WARNING=>" + $global:WarningCount
$global:OutMessage+="`r`n" + $global:OutMessageTemp
write-host $global:OutMessage
exit $global:Exitcode
