#Edited by @wetcoriginal for Centreon
#usage : ./check_dhcp_scope.ps1
Param (
    #Threshold defining the minimum number of IPs in the scope in order to check the remaining space in % rather than the number of remaining IPs.
    #LowScope ignores scopes with too little IP
	[ValidateRange(0,100)][Int]
	$Treshold = 21,
	#Value in percent defining the warning limit
	[ValidateRange(0,100)][Int]
	$WarningPercent = 75,
	#Value in percent defining the critical limit
	[ValidateRange(0,100)][Int]
	$CriticalPercent = 90,
	#Remaining available IP value defining the warning limit
	[ValidateRange(0,100)][Int]
	$WarningFree = 10,
	#Remaining available IP value defining the critical limit
	[ValidateRange(0,100)][Int]
	$CriticalFree = 5,
	#Remaining available IP value defining the critical limit
	[ValidateRange(0,100)][Int]
	$LowScope = 6
)

$Message = ""

$IsWarning  = 0
$IsCritical = 0
$IsOk = 0

$ActiveScopes = Get-DhcpServerv4Scope | Where { $_.State -eq 'Active' }

# Initialize the counts for each status
$global:WarningCount = 0
$global:CriticalCount = 0
$global:OkCount = 0

if ($ActiveScopes) {
	$ActiveScopes | Foreach {
		$Scope = $_
		$Stats = Get-DhcpServerv4ScopeStatistics -ScopeId $Scope.ScopeId
        $TotalIp = (Get-DhcpServerv4ScopeStatistics -ScopeId $Scope.ScopeId | Select-Object -ExpandProperty Free) + (Get-DhcpServerv4ScopeStatistics -ScopeId $Scope.ScopeId | Select-Object -ExpandProperty InUse)
        $IpInUse = Get-DhcpServerv4ScopeStatistics -ScopeId $Scope.ScopeId | Select-Object -ExpandProperty InUse
        $IpLibre = Get-DhcpServerv4ScopeStatistics -ScopeId $Scope.ScopeId | Select-Object -ExpandProperty Free
		$Used = [Int] $Stats.PercentageInUse
        $Free = [Int] $Stats.Free

   if (($TotalIp -le $Treshold) -and ($TotalIp -ge $LowScope)) {
    # Check if scope is in critical status based on $Free
    if ($Free -le $CriticalFree) {
        $IsCritical = $IsCritical + 1
        $Message += "CRITICAL - Le scope $($Scope.Name) n'a plus que $Free IP's disponible`n"
        # Increment the count for the CRITICAL status
        $global:CriticalCount++
    }
    # Check if scope is in warning status based on $Free and not critical
    elseif ($Free -le $WarningFree) {
        $IsWarning = $IsWarning + 1
        $Message += "WARNING - Le scope $($Scope.Name) n'a plus que $Free IP's disponible`n"
        # Increment the count for the WARNING status
        $global:WarningCount++
    }
    # If the scope is not in WARNING or CRITICAL status, it must be OK
    # but we will not display any information about it
    else {
        # Increment the count for the OK status
        $global:OkCount++
		}
}
if ($TotalIp -le $LowScope) {
    if ($Free -eq 0) {
        $IsCritical = $IsCritical + 1
        $Message += "CRITICAL - Plus d'IP disponible dans le scope $($Scope.Name) `n"
        # Increment the count for the CRITICAL status
        $global:CriticalCount++
}
}
else {
   if (($TotalIp -ge $Treshold) -and ($TotalIp -ge $LowScope)) {
    # Check if scope is in critical status based on $Used
    if ($Used -ge $CriticalPercent) {
        $IsCritical = $IsCritical + 1
        $Message += "CRITICAL - Le scope $($Scope.Name) est utilisé à $Used% `n"
        # Increment the count for the CRITICAL status
        $global:CriticalCount++
    }
    # Check if scope is in warning status and not critical
    elseif ($Used -ge $WarningPercent) {
        $IsWarning = $IsWarning + 1
        $Message += "WARNING - Le scope $($Scope.Name) est utilisé à $Used% `n"
        # Increment the count for the WARNING status
        $global:WarningCount++
    }
    # If the scope is not in WARNING or CRITICAL status, it must be OK
    # but we will not display any information about it
    else {
        # Increment the count for the OK status
        $global:OkCount++
		}
	}
}
}
}

# Calculate the total number of scopes
$TotalCount = $global:WarningCount + $global:CriticalCount + $global:OkCount

if ($Message) {
	$output = $Message | Out-String
}

if ($IsCritical -gt 0) {
	# Set the exit code to 2 if there are any CRITICAL scopes
	$global:ExitCode = 2
}
elseif ($IsWarning -gt 0) {
	# Set the exit code to 1 if there are any WARNING scopes
	$global:ExitCode = 1
}
else {
	# If there are no WARNING or CRITICAL scopes, the exit code is 0
	$global:ExitCode = 0
}


#Ajout du nombre total d'erreur détectés
$TotalCount=$global:WarningCount + $global:CriticalCount + $global:OkCount
$global:OutMessage="TOTAL=>" + $TotalCount + " / OK=>" + $global:OkCount + " / CRITICAL=>" + $global:CriticalCount + " / WARNING=>" + $global:WarningCount
$global:OutMessage+="`r`n"


Write-Output $global:OutMessage
Write-Output $output
exit $global:ExitCode
