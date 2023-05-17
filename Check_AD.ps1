$command = "dcdiag /test:services /test:replications /test:advertising /test:fsmocheck /test:ridmanager /test:machineaccount"
$result = Invoke-Expression -Command $command
 
$testResults = $result | Select-String "Starting test:", "........................."
 
$allTestsPassed = $true
 
$testOutput = @{}
 
# Ajout de variables
$global:OutMessage = ""
$global:ExitCode = ""
$global:WarningDisabledCount = 0
$global:WarningCount = 0
$global:CriticalCount = 0
 
 
foreach ($test in $testResults) {
    $line = $test.ToString()
 
    if ($line -match "Starting test: (.+)") {
        $testName = $Matches[1].Trim()
        $testOutput[$testName] = ""
    } elseif ($line -match "([A-Za-z0-9_-]+) (passed|failed) test (.+)") {
        $server = $Matches[1].Trim()
        $testStatus = $Matches[2].Trim()
 
        if ($testStatus -eq "failed") {
            $allTestsPassed = $false
        }
 
        $testOutput[$testName] += "${server}: $testStatus. "
    }
}
 
$output = ""
 
foreach ($test in $testOutput.GetEnumerator() | Sort-Object Name) {
    $testName = $test.Key
    $testStatus = $test.Value
 
    if ($testStatus -match "failed") {
        $output += "${testName}: CRITICAL. "
    } else {
        $output += "${testName}: OK. "
    }
}
 
$output = $output.TrimEnd(". ") # Remove trailing period and space
 
if ($allTestsPassed) {
    Write-Host "OK - $output"
    $global:OkCount++
} else {
    $global:ExitCode = 2
    $global:OutMessage += "CRITICAL - $output"
    $global:CriticalCount++
}
$global:TotalCount = $global:OkCount + $global:WarningCount + $global:CriticalCount
Write-Host $global:OutMessage
exit $global:Exitcode
