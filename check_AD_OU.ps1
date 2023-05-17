# ====================================================================
# Search in AD for default OU computer. To be used through NRPE / nsclient++
# Edited by @wetcoriginal
# ====================================================================
#
# Require Set-ExecutionPolicy RemoteSigned.
#
# ============================================================
#
param 
(
	[string]$action = "Present in Computers OU",
	[string]$searchBase = "",
	[int]$maxWarn = 0,
	[int]$maxCrit = 1
)

# check that powershell ActiveDirectory module is present
if(Get-Module -Name "ActiveDirectory" -ListAvailable)
{
	try
	{
		Import-Module -Name ActiveDirectory
	}
	catch
	{
		Write-Host "CRITICAL: Missing PowerShell ActiveDirectory module"
		exit 2
	}
}
else
{
	Write-Host "CRITICAL: Missing PowerShell ActiveDirectory module"
	exit 2
}

if(($searchBase -ne "") -and $searchBase -ne ((Get-ADDomain).DistinguishedName))
{
	$search=Get-ADObject -Filter 'ObjectClass -eq "OrganizationalUnit" -and DistinguishedName -eq $searchBase'
	if ($search.Count -ne 1)
	{
		Write-Host "CRITICAL: SearchBase not found or duplicate. Provided $searchBase"
		exit 2
	}
}
else
{
	$searchBase=(Get-ADDomain).DistinguishedName
}

#Dont forget to edit the SearchBase filter to match with ur domain
$command="Get-ADComputer -Filter * -SearchBase 'CN=Computers,DC=MYDOMAIN,DC=com'"
$result=invoke-expression $command
$array= $result -split "&nbsp;"

if($array.count -gt $maxCrit)
{
	$state="CRITICAL"
	$exitcode=2
    $output="CRITICAL: Some PC present in Computers OU : "
    $List=Get-ADComputer -Filter * -SearchBase 'CN=Computers,DC=MYDOMAIN,DC=com' | Foreach-Object Name
    Write-Host $output
    Write-Host $List
}
elseif($array.count -gt $maxWarn)
{
	$state="WARNING"
	$exitcode=1
    $output="WARNING: 1 PC present in Computers OU : "
    $List=Get-ADComputer -Filter * -SearchBase 'CN=Computers,DC=MYDOMAIN,DC=com' | Foreach-Object Name
    Write-Host $output
    Write-Host $List
}
else
{
	$state="OK"
	$exitcode=0
    $output="OK: No PC present in Computers OU"
    Write-Host $output
}

exit $exitcode
