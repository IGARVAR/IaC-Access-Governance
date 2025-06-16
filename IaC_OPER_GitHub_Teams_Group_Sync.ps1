<#
.SYNOPSIS
Synchronizes GitHub organization team memberships with Active Directory groups or Microsoft Teams.

.DESCRIPTION
Reads a `permissions.csv` or `teams.yaml` exported from a GitHub organization (or GitHub Actions workflow) and maps GitHub team roles to local AD groups or M365 Teams. Ensures centralized, IaC-driven access provisioning.

Use case: Enterprise teams managing access through GitHub workflows / PR reviews, with mirrored access in Microsoft environment.

.NOTES
Author: Ivan Garkusha
Filename: IaC_OPER_GitHub_Teams_Group_Sync.ps1
Version: 1.0

.EXAMPLE
# CSV example:
# TeamName, GitHubTeam, TargetADGroup, Role
# DevOps, devops-team, ROLE_AD_DEVOPS, member

.REQUIREMENTS
- PowerShell
- AD module or MS Graph SDK
- GitHub export (CSV or YAML)
#>

# === CONFIGURATION ===
$InputCsvPath = "E:\Sync\GitHub\permissions.csv"
$LogPath = "E:\Logs\GitHub_AD_Sync_$(Get-Date -Format 'yyyyMMdd').log"
$SimulationOnly = $true  # Set to $false to apply changes

# === LOGGING FUNCTION ===
function Log($msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts - $msg" | Tee-Object -FilePath $LogPath -Append
}

# === LOAD MAPPINGS ===
if (-not (Test-Path $InputCsvPath)) { Log "Mapping file not found at $InputCsvPath"; exit 1 }

$mappings = Import-Csv -Path $InputCsvPath
Log "Loaded $($mappings.Count) GitHub -> AD mappings."

# === MAIN LOOP ===
foreach ($map in $mappings) {
    $ghTeam = $map.GitHubTeam
    $adGroup = $map.TargetADGroup
    $role = $map.Role

    Log "Checking AD group: $adGroup for GitHub team: $ghTeam"

    # Simulate GitHub call (replace with GitHub API call if needed)
    $members = @("user1@example.com", "user2@example.com")  # ← Mocked

    foreach ($userUPN in $members) {
        $user = Get-ADUser -Filter { UserPrincipalName -eq $userUPN } -ErrorAction SilentlyContinue
        if ($user) {
            if ($SimulationOnly) {
                Log "[SIMULATION] Would add $userUPN to $adGroup"
            } else {
                Add-ADGroupMember -Identity $adGroup -Members $user -ErrorAction Stop
                Log "Added $userUPN to $adGroup"
            }
        } else {
            Log "User not found in AD: $userUPN"
        }
    }
}

Log "SCRIPT COMPLETE"
