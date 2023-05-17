# ====================================================================
# Search computers without LAPS in AD in OU computers. To be used through NRPE / nsclient++
# Author: @wetcoriginal
# ====================================================================
 
#
# Require Set-ExecutionPolicy RemoteSigned.
#
 
# ============================================================
#
param
(
[int]$value = 0
)
 
#Liste des PC présent dans l'OU :
$Compte=Get-ADComputer -Filter {(enabled -eq $TRUE)} -SearchBase 'OU=Ordinateurs,DC=domain,DC=lan' -SearchScope Subtree | Foreach-Object Name
#Count du nombre de PC présent dans l'OU :
$AllComputersCount=(Get-ADComputer -Filter 'enabled -eq $TRUE' -SearchBase 'OU=Ordinateurs,DC=domain,DC=lan').Count
#Nombre de PC présent dans l'OU ayant LAPS
$YesLAPS=(Get-ADComputer -Filter 'enabled -eq $TRUE' -Properties Name,ms-Mcs-AdmPwdExpirationTime -SearchBase 'OU=Ordinateurs,DC=domain,DC=lan' | Where-Object ms-Mcs-AdmPwdExpirationTime -ne $null).count
#Nombre de PC n'ayant pas LAPS
$NoLAPSCount=(Get-ADComputer -Filter 'enabled -eq $TRUE' -Properties Name,ms-Mcs-AdmPwdExpirationTime -SearchBase 'OU=Ordinateurs,DC=domain,DC=lan' | Where-Object ms-Mcs-AdmPwdExpirationTime -eq $null).count
#Liste des PC présent dans l'OU n'ayant pas LAPS
$NoLAPS=Get-ADComputer -Filter 'enabled -eq $TRUE' -Properties Name,ms-Mcs-AdmPwdExpirationTime -SearchBase 'OU=Ordinateurs,DC=domain,DC=lan' | Where-Object ms-Mcs-AdmPwdExpirationTime -eq $null| Format-Table Name | out-string
 
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
$state="CRITICAL"
$exitcode=2
exit 2
}
 
if(($AllComputersCount -ne $YesLAPS) -and ($value -ne $NoLAPS))
{
Write-Host "CRITICAL: Les PC suivants n'ont pas LAPS d'installé dans l'OU 'Ordinateurs' :"
Write-Host $NoLAPS
$state="CRITICAL"
$exitcode=2
exit 2
}
else
{
$state="OK"
$exitcode=0
$output="OK: Pas de PC n'ayant pas LAPS d'installé présent dans l'OU 'Ordinateurs'"
Write-Host $output
}
 
exit $exitcode
