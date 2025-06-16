<#
.SYNOPSIS
Audit Active Directory groups lacking ownership, metadata, or members — potential governance risk.

.DESCRIPTION
This script scans all AD groups and flags potentially orphaned or abandoned groups:
- No `managedBy`
- Empty `description`
- Zero members
- Empty classification or sensitivity attributes

These groups are marked for manual review or deletion under Zero Trust / least-privilege strategies.

.NOTES
Author: Ivan Garkusha
Filename: IaC_REPORT_ZeroTrust_Orphaned_AD_Groups.ps1
Version: 1.0

.REQUIREMENTS
- Active Directory PowerShell module
- Read access to AD groups
- Optional extensionAttribute1/2 fields used for classification
#>

# === CONFIGURATION ===
$OutputPath = "E:\Scripts\Reports\AD_Orphaned_Groups_$(Get-Date -Format 'yyyyMMdd').csv"
$LogPath = "E:\Scripts\Logs\ZeroTrust_AD_Orphaned_$(Get-Date -Format 'yyyyMMdd').log"

# === LOGGING FUNCTION ===
function Log-Info($msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts - $msg" | Tee-Object -FilePath $LogPath -Append
}

# === GET ALL GROUPS ===
Log-Info "Starting AD orphaned group audit..."
$groups = Get-ADGroup -Filter * -Properties ManagedBy, Description, Members, extensionAttribute1, extensionAttribute2
Log-Info "Total groups found: $($groups.Count)"

# === FILTER ORPHANED GROUPS ===
$orphans = $groups | Where-Object {
    -not $_.ManagedBy -and
    -not $_.Description -and
    -not $_.Members -and
    (-not $_.extensionAttribute1 -or $_.extensionAttribute1 -eq '') -and
    (-not $_.extensionAttribute2 -or $_.extensionAttribute2 -eq '')
}

Log-Info "Orphaned candidates found: $($orphans.Count)"

# === EXPORT REPORT ===
$orphans | Select-Object Name, DistinguishedName, WhenCreated, GroupScope, GroupCategory |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Log-Info "Report exported to: $OutputPath"

# === CLEANUP ===
Remove-Variable -Name groups, orphans -ErrorAction SilentlyContinue
Log-Info "SCRIPT FINISHED"
