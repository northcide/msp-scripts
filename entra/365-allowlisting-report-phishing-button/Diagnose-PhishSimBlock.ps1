#Requires -Version 7.1
<#
.SYNOPSIS
    Diagnostic for PhishSim cmdlet failures on a tenant.

.DESCRIPTION
    Captures the verbose HTTP status code from Get-PhishSimOverridePolicy and
    New-PhishSimOverridePolicy, checks related Defender cmdlets, lists
    role-group capability flags (looking for Partner_Managed), and dumps
    tenant SKUs. Use when Sync-AllowlistReport.ps1 reports the PhishSim
    section as SKIPPED or FAILED on a tenant where you expect it to work.

    Read-only: makes no changes to the tenant. All Set-/New-/Add- cmdlets use
    -WhatIf or are wrapped in try/catch.

.PARAMETER SignInAs
    Optional UPN to pre-fill in the browser sign-in. Use to force a specific
    account when a cached token is for the wrong tenant or wrong user.

.EXAMPLE
    .\Diagnose-PhishSimBlock.ps1
    Interactive sign-in.

.EXAMPLE
    .\Diagnose-PhishSimBlock.ps1 -SignInAs admin@newclient.onmicrosoft.com
    Force sign-in as the given account.
#>

[CmdletBinding()]
param(
    [string] $SignInAs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function Write-Step    { param([string]$Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-OK      { param([string]$Msg) Write-Host "   [OK]  $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "   [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Msg) Write-Host "   [XX]  $Msg" -ForegroundColor Red }

# ── Module bootstrap ────────────────────────────────────────────────────────
Write-Step "Module bootstrap"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Warn "Installing ExchangeOnlineManagement..."
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-OK "ExchangeOnlineManagement loaded."

# ── Connect (force fresh session) ───────────────────────────────────────────
Write-Step "Connecting to Exchange Online"
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}

$connectParams = @{ ShowBanner = $false; ErrorAction = 'Stop' }
if ($SignInAs) {
    $connectParams.UserPrincipalName = $SignInAs
    Write-Host "   Pre-filling: $SignInAs" -ForegroundColor DarkGray
}
try {
    Connect-ExchangeOnline @connectParams
    Write-OK "Connected."
} catch {
    Write-Fail "Connect-ExchangeOnline failed: $($_.Exception.Message)"
    exit 1
}

# ── Connection context ──────────────────────────────────────────────────────
Write-Step "Connection context"
Get-ConnectionInformation | Select-Object UserPrincipalName, TenantID, ConnectionUri, TokenStatus, State | Format-List

# ── Tenant SKUs (Defender presence) ─────────────────────────────────────────
Write-Step "Tenant SKUs (looking for ATP / Defender)"
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.DirectoryManagement)) {
        Write-Warn "Microsoft.Graph.Identity.DirectoryManagement not installed; skipping SKU check."
    } else {
        Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
        Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome -ErrorAction Stop
        Get-MgSubscribedSku |
            Select-Object SkuPartNumber, ConsumedUnits, @{n='Enabled';e={$_.PrepaidUnits.Enabled}} |
            Format-Table -AutoSize

        Write-Host "Service plans matching 'ATP|THREAT|DEFENDER':" -ForegroundColor DarkGray
        Get-MgSubscribedSku |
            Select-Object -ExpandProperty ServicePlans |
            Where-Object { $_.ServicePlanName -match 'ATP|THREAT|DEFENDER' } |
            Select-Object ServicePlanName, ProvisioningStatus -Unique |
            Format-Table -AutoSize

        Disconnect-MgGraph | Out-Null
    }
} catch {
    Write-Fail "SKU check failed: $($_.Exception.Message)"
}

# ── Get-PhishSimOverridePolicy verbose (HTTP status code) ───────────────────
Write-Step "Get-PhishSimOverridePolicy (verbose — looking for HTTP code)"
try {
    Get-PhishSimOverridePolicy -ErrorAction Stop -Verbose 4>&1 | Select-Object -First 30
} catch {
    Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red
}

# ── New-PhishSimOverridePolicy -WhatIf (does the create path differ?) ────────
Write-Step "New-PhishSimOverridePolicy -WhatIf verbose"
try {
    New-PhishSimOverridePolicy -Name PhishSimOverridePolicy -WhatIf -ErrorAction Stop -Verbose 4>&1 |
        Select-Object -First 30
} catch {
    Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red
}

# ── Sibling Defender cmdlets that should work for GA ────────────────────────
Write-Step "Other Defender cmdlets (do these work? if yes, problem is PhishSim-specific)"

Write-Host ">> Get-ReportSubmissionPolicy"
try {
    Get-ReportSubmissionPolicy -ErrorAction Stop | Select-Object Identity, EnableReportToMicrosoft | Format-List
} catch { Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red }

Write-Host ">> Get-AntiPhishPolicy"
try {
    Get-AntiPhishPolicy -ErrorAction Stop | Select-Object -First 1 Identity, IsDefault | Format-List
} catch { Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red }

Write-Host ">> Get-EmailTenantSettings"
try {
    Get-EmailTenantSettings -ErrorAction Stop | Select-Object Identity, EnablePriorityAccountProtection | Format-List
} catch { Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red }

Write-Host ">> Get-HostedConnectionFilterPolicy"
try {
    (Get-HostedConnectionFilterPolicy -Identity Default -ErrorAction Stop).IPAllowList |
        Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    Write-Host "  (showing first 3 of $((Get-HostedConnectionFilterPolicy -Identity Default).IPAllowList.Count))" -ForegroundColor DarkGray
} catch { Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red }

Write-Host ">> Get-TenantAllowBlockListItems (URLs, AdvancedDelivery)"
try {
    $tbl = @(Get-TenantAllowBlockListItems -ListType Url -ListSubType AdvancedDelivery -ErrorAction Stop)
    Write-Host "  $($tbl.Count) entry(ies)" -ForegroundColor DarkGray
} catch { Write-Host "  ERR: $($_.Exception.Message)" -ForegroundColor Red }

# ── Role group capability flags (Partner_Managed = smoking gun) ─────────────
Write-Step "Role groups (looking for Partner_Managed / RoleGroupType anomalies)"
try {
    $rgs = Get-RoleGroup -ErrorAction Stop
    $rgs | Where-Object {
        $_.Name -match 'Admin|Security|Org' -or $_.RoleGroupType -ne 'Standard'
    } | Select-Object Name, DisplayName, RoleGroupType, @{n='Capabilities';e={$_.Capabilities -join ','}} |
        Sort-Object Name | Format-Table -AutoSize

    Write-Host "Any with 'Partner_Managed' capability:" -ForegroundColor DarkGray
    $partnerManaged = @($rgs | Where-Object { ($_.Capabilities -join ',') -match 'Partner_Managed' })
    if ($partnerManaged.Count -gt 0) {
        $partnerManaged | Select-Object Name, DisplayName | Format-Table -AutoSize
        Write-Host "    ^^^ This means certain settings are controlled by an upstream CSP partner." -ForegroundColor Yellow
        Write-Host "        PhishSim cmdlets check this and refuse even for tenant-level GA." -ForegroundColor Yellow
    } else {
        Write-Host "  (none)" -ForegroundColor DarkGray
    }
} catch {
    Write-Fail "Get-RoleGroup failed: $($_.Exception.Message)"
}

# ── Check effective Defender XDR Unified RBAC status ────────────────────────
Write-Step "Defender XDR Unified RBAC indicators"
try {
    # SecurityAdmins_<id> is the bridge role group populated from Entra
    # Security Administrator assignments. Empty RoleAssignments on it is the
    # signature of "Unified RBAC owns this but we haven't been delegated."
    $sa = Get-RoleGroup -Identity SecurityAdmins* -ErrorAction SilentlyContinue
    if ($sa) {
        foreach ($g in @($sa)) {
            Write-Host ">> $($g.Name)"
            $g | Select-Object Name, DisplayName, RoleAssignments, @{n='Caps';e={$_.Capabilities -join ','}} |
                Format-List
            Write-Host "Members:" -ForegroundColor DarkGray
            try {
                Get-RoleGroupMember -Identity $g.Identity -ResultSize Unlimited -ErrorAction Stop |
                    Select-Object Name, PrimarySmtpAddress | Format-Table -AutoSize
            } catch { Write-Host "  members read err: $($_.Exception.Message)" -ForegroundColor Red }
        }
    } else {
        Write-Host "  No SecurityAdmins_* role group found." -ForegroundColor DarkGray
    }
} catch {
    Write-Fail "$($_.Exception.Message)"
}

# ── Effective user RBAC: am I in Organization Management ──────────────────────
Write-Step "Effective RBAC for signed-in user"
try {
    $me = (Get-ConnectionInformation | Select-Object -First 1).UserPrincipalName
    Write-Host "Signed in as: $me" -ForegroundColor DarkGray
    Write-Host "Role groups containing this user (direct or transitive):" -ForegroundColor DarkGray
    Get-RoleGroup -ErrorAction SilentlyContinue | ForEach-Object {
        $g = $_
        try {
            $members = Get-RoleGroupMember -Identity $g.Identity -ResultSize Unlimited -ErrorAction Stop
            if ($members | Where-Object { $_.PrimarySmtpAddress -eq $me -or $_.Name -eq ($me -split '@')[0] -or $_.UserPrincipalName -eq $me }) {
                Write-Host "    $($g.Name)" -ForegroundColor Green
            }
        } catch {}
    }
} catch {
    Write-Fail "$($_.Exception.Message)"
}

# ── Cleanup ─────────────────────────────────────────────────────────────────
Write-Step "Disconnecting"
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}
Write-OK "Done."

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Paste the full output above into chat for analysis." -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
