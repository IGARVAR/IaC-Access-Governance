<#
.SYNOPSIS
Sets 'managedBy' and key extension attributes for AD groups (ROLE/RES) based on a CSV mapping file.

.DESCRIPTION
This governance-focused script automates assigning group owners (`managedBy`) and sets attributes such as `extensionAttribute1`, `extensionAttribute2` for security classification and sensitivity.
Useful in enforcing Zero Trust and reducing orphaned or mismanaged groups.

.REQUIREMENTS
- Active Directory PowerShell module
- Permission to modify group attributes
- CSV file with columns: GroupName, OwnerUPN, Classification, Sensitivity

.NOTES
Author: Ivan Garkusha
Filename: IaC_OPER_SetGroupOwners_FromCSV.ps1
Version: 1.0
#>

# === CONFIGURATION ===
$CsvFilePath = "E:\Scripts\GroupOwnershipMapping.csv"
$LogFilePath = "E:\Scripts\Logs\SetGroupOwners_$(Get-Date -Format 'yyyyMMdd').log"
$ReportPath = "E:\Scripts\Reports\Orphaned_Groups_Report_$(Get-Date -Format 'yyyyMMdd').csv"

# === LOGGING FUNCTION ===
function Log-Info($msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts - $msg" | Tee-Object -FilePath $LogFilePath -Append
}

# === VALIDATE FILE ===
if (-not (Test-Path $CsvFilePath)) {
    Log-Info "CSV file not found: $CsvFilePath"
    exit 1
}

# === READ MAPPING ===
$entries = Import-Csv -Path $CsvFilePath
if (-not $entries) {
    Log-Info "No entries found in CSV"
    exit 0
}

Log-Info "Processing $($entries.Count) entries from CSV"

# === INITIALIZE REPORT ===
$report = @()

# === MAIN PROCESSING ===
foreach ($entry in $entries) {
    $grpName = $entry.GroupName.Trim()
    $ownerUPN = $entry.OwnerUPN.Trim()
    $classification = $entry.Classification.Trim()
    $sensitivity = $entry.Sensitivity.Trim()

    Try {
        # Validate group
        $group = Get-ADGroup -Identity $grpName -Properties ManagedBy, extensionAttribute1, extensionAttribute2 -ErrorAction Stop

        # Validate owner
        $owner = Get-ADUser -Filter { UserPrincipalName -eq $ownerUPN } -ErrorAction Stop
        if (-not $owner) { Throw "Owner $ownerUPN not found in AD" }

        # Update attributes
        Set-ADGroup -Identity $group -ManagedBy $owner.DistinguishedName -Add @{
            extensionAttribute1 = $classification
            extensionAttribute2 = $sensitivity
        }

        Log-Info "Updated group '$grpName' - Owner: $ownerUPN | Class: $classification | Sens: $sensitivity"
    } Catch {
        $report += [pscustomobject]@{
            GroupName      = $grpName
            OwnerUPN       = $ownerUPN
            Error          = $_.Exception.Message
        }
        Log-Info "Failed to update group '$grpName': $_"
    }
}

# === EXPORT FAILURES ===
if ($report.Count -gt 0) {
    $report | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Log-Info "Report saved: $ReportPath"
} else {
    Log-Info "All groups processed successfully."
}

# === CLEANUP ===
Remove-Variable -Name grpName, ownerUPN, classification, sensitivity, entry, group, owner, entries, report -ErrorAction SilentlyContinue
Log-Info "SCRIPT FINISHED"
