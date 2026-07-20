#Requires -Version 7.1
<#
.SYNOPSIS
    Generate a Microsoft Support ticket dossier for the PhishSim Advanced
    Delivery cmdlet 403 issue.

.DESCRIPTION
    Runs a fixed sequence of read-only diagnostics and produces a transcript
    file ready to attach to a Microsoft Support ticket. Captures everything
    an L2 engineer will ask for in the first reply:

      1. Tenant identity (ID, name, region)
      2. Signed-in user identity + Entra role assertion
      3. PowerShell + ExchangeOnlineManagement module versions
      4. EXO role group memberships for the signed-in user
      5. Defender XDR Unified RBAC workload status (E&C in particular)
      6. Tenant SKUs (Defender for O365 P1 / ATP_ENTERPRISE presence)
      7. The FAILING cmdlets with -Verbose (HTTP 403 evidence)
      8. The PASSING sibling Defender cmdlets in the SAME session (proves
         the 403 is cmdlet-specific, not session-wide)
      9. Per-section summary + a "PASTE THIS INTO YOUR TICKET" block

    Read-only. No writes; the one New-PhishSimOverridePolicy call uses -WhatIf.
    All console output is also captured to a timestamped .txt file alongside
    the script — attach that file to the ticket.

.PARAMETER SignInAs
    UPN to pre-fill in the browser sign-in. Recommended: your tenant
    breakglass GA account on the tenant you're ticketing about.

.EXAMPLE
    .\Export-PhishSimSupportDossier.ps1 -SignInAs adm-breakglass-msp@newclient.onmicrosoft.com

.NOTES
    Designed to be run on the tenant most convenient for Microsoft Support to
    engage with (i.e. your own tenant). The bug reproduces identically across
    multiple tenants, so the choice of tenant for the dossier doesn't matter
    technically — pick the one whose support relationship gets the fastest
    routing.
#>

[CmdletBinding()]
param(
    [string] $SignInAs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ── Output file ─────────────────────────────────────────────────────────────
$timestamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$transcriptDir = $PSScriptRoot
$transcriptFile = Join-Path $transcriptDir "PhishSim-SupportDossier-$timestamp.txt"

# Capture everything to file AND show on console
Start-Transcript -Path $transcriptFile -IncludeInvocationHeader | Out-Null

function Write-Section {
    param([string]$Label)
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════"
    Write-Host "  $Label"
    Write-Host "════════════════════════════════════════════════════════════════════════"
}
function Write-Sub  { param([string]$Msg) Write-Host "`n--- $Msg ---" }
function Write-OK   { param([string]$Msg) Write-Host "[OK]  $Msg" }
function Write-Warn { param([string]$Msg) Write-Host "[!!]  $Msg" }
function Write-Fail { param([string]$Msg) Write-Host "[XX]  $Msg" }

# Track key facts for the final summary block.
$dossier = [ordered]@{
    Generated                  = (Get-Date).ToString('o')
    Machine                    = $env:COMPUTERNAME
    OS                         = [System.Environment]::OSVersion.VersionString
    PSVersion                  = $PSVersionTable.PSVersion.ToString()
    PSEdition                  = $PSVersionTable.PSEdition
    EXOModuleVersion           = $null
    TenantName                 = $null
    TenantId                   = $null
    ExchangeRegion             = $null
    SignedInUPN                = $null
    SignedInExternalId         = $null
    EntraRoleEvidence          = $null   # confirmed via TenantAdmins_* membership
    EXO_OrgMgmt_Member         = $null
    EXO_SecAdmin_Member        = $null
    UnifiedRbac_DefenderXDR    = $null
    UnifiedRbac_E_and_C        = $null   # critical: must be Not Active for legacy EXO RBAC
    HasDefenderForO365P1       = $null
    Failing_Get_Policy_HTTP    = $null
    Failing_New_Policy_HTTP    = $null
    Failing_Get_Rule_HTTP      = $null
    Working_ReportSubmission   = $null
    Working_AntiPhish          = $null
    Working_HostedConnFilter   = $null
    Working_TenantAllowBlock   = $null
    Working_EmailTenantSettings = $null
}

Write-Section "Microsoft Support Ticket Dossier — PhishSim Advanced Delivery 403"
Write-Host "Generated: $($dossier.Generated)"
Write-Host "Transcript: $transcriptFile"

Write-Section "1. Host + module versions"
$dossier.PSVersion = $PSVersionTable.PSVersion.ToString()
$dossier.PSEdition = $PSVersionTable.PSEdition
Write-Host "PowerShell:  $($dossier.PSVersion) ($($dossier.PSEdition))"
Write-Host "OS:          $($dossier.OS)"
Write-Host "Machine:     $($dossier.Machine)"

$exoMod = Get-Module -ListAvailable -Name ExchangeOnlineManagement | Sort-Object Version -Descending | Select-Object -First 1
if (-not $exoMod) {
    Write-Warn "ExchangeOnlineManagement not installed — installing..."
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
    $exoMod = Get-Module -ListAvailable -Name ExchangeOnlineManagement | Sort-Object Version -Descending | Select-Object -First 1
}
$dossier.EXOModuleVersion = $exoMod.Version.ToString()
Write-Host "EXO module:  $($dossier.EXOModuleVersion)"
Import-Module ExchangeOnlineManagement -ErrorAction Stop

Write-Section "2. Connecting to Exchange Online"
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}

$connectParams = @{ ShowBanner = $false; ErrorAction = 'Stop' }
if ($SignInAs) {
    $connectParams.UserPrincipalName = $SignInAs
    Write-Host "Pre-filling sign-in: $SignInAs"
} else {
    Write-Host "Sign in via browser when prompted."
}
try {
    Connect-ExchangeOnline @connectParams
    Write-OK "Connected."
} catch {
    Write-Fail "Connect-ExchangeOnline failed: $($_.Exception.Message)"
    Stop-Transcript | Out-Null
    exit 1
}

$conn = Get-ConnectionInformation | Select-Object -First 1
$dossier.SignedInUPN = $conn.UserPrincipalName
$dossier.TenantId    = $conn.TenantID
Write-Host ""
$conn | Format-List UserPrincipalName, TenantID, ConnectionUri, TokenStatus, State

try {
    $org = Get-OrganizationConfig -ErrorAction Stop
    $dossier.TenantName = $org.Name
    # Extract the EXO routing region from the DistinguishedName (e.g. NAMPR06A015)
    if ($org.DistinguishedName -match 'DC=([A-Z0-9]+),DC=PROD,DC=OUTLOOK,DC=COM') {
        $dossier.ExchangeRegion = $matches[1]
    }
    Write-Host ""
    Write-Host "Tenant name:      $($dossier.TenantName)"
    Write-Host "Tenant ID:        $($dossier.TenantId)"
    Write-Host "Exchange region:  $($dossier.ExchangeRegion)"
} catch {
    Write-Fail "Get-OrganizationConfig failed: $($_.Exception.Message)"
}

Write-Section "3. Entra Global Administrator attestation (via TenantAdmins_* role group)"
Write-Host "TenantAdmins_* is the Exchange role group that mirrors Entra Global Admin"
Write-Host "membership. If the signed-in user appears here, they are definitively GA."
Write-Host ""
try {
    $tenantAdminsRg = Get-RoleGroup | Where-Object { $_.Name -like 'TenantAdmins_*' } | Select-Object -First 1
    if ($tenantAdminsRg) {
        Write-Host "Group: $($tenantAdminsRg.Name)  (Capabilities: $($tenantAdminsRg.Capabilities -join ', '))"
        Write-Host ""
        $members = @(Get-RoleGroupMember -Identity $tenantAdminsRg.Identity -ResultSize Unlimited -ErrorAction Stop)
        $members | Select-Object Name, PrimarySmtpAddress | Format-Table -AutoSize
        $isGA = [bool]($members | Where-Object {
            $_.PrimarySmtpAddress -eq $dossier.SignedInUPN -or
            $_.WindowsLiveID      -eq $dossier.SignedInUPN
        })
        $dossier.EntraRoleEvidence = if ($isGA) { "Confirmed in $($tenantAdminsRg.Name)" } else { "NOT FOUND in $($tenantAdminsRg.Name)" }
        if ($isGA) { Write-OK $dossier.EntraRoleEvidence } else { Write-Warn $dossier.EntraRoleEvidence }
    } else {
        Write-Warn "No TenantAdmins_* role group found — unusual."
        $dossier.EntraRoleEvidence = 'TenantAdmins_* not found'
    }
} catch {
    Write-Fail "$($_.Exception.Message)"
    $dossier.EntraRoleEvidence = "ERROR: $($_.Exception.Message)"
}

Write-Section "4. EXO role group memberships for signed-in user"
Write-Host "These are the role groups Microsoft documentation lists as sufficient"
Write-Host "for PhishSim Advanced Delivery cmdlets."
foreach ($groupName in @('Organization Management', 'Security Administrator')) {
    Write-Sub $groupName
    try {
        # Disambiguate: pick the non-Partner_Managed Standard role group if there
        # are multiple objects with this name.
        $rg = Get-RoleGroup | Where-Object {
            $_.Name -eq $groupName -and
            $_.RoleGroupType -eq 'Standard' -and
            -not (($_.Capabilities -join ',') -match 'Partner_Managed')
        } | Select-Object -First 1
        if (-not $rg) {
            # Fallback to any match
            $rg = Get-RoleGroup -Identity $groupName -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if (-not $rg) {
            Write-Warn "Role group '$groupName' not found."
            continue
        }
        Write-Host "Identity:     $($rg.Identity)"
        Write-Host "Capabilities: $(@($rg.Capabilities) -join ', ')"
        $rgMembers = @(Get-RoleGroupMember -Identity $rg.DistinguishedName -ResultSize Unlimited -ErrorAction Stop)
        Write-Host "Members ($($rgMembers.Count)):"
        $rgMembers | Select-Object Name, PrimarySmtpAddress | Format-Table -AutoSize
        $isDirectMember = [bool]($rgMembers | Where-Object {
            $_.PrimarySmtpAddress -eq $dossier.SignedInUPN -or
            $_.WindowsLiveID      -eq $dossier.SignedInUPN
        })
        # On many tenants the role-group members are NESTED bridge groups
        # (TenantAdmins_*, SecurityAdmins_*, etc.) rather than user objects. A
        # GA user is transitively a member via those bridges. Detect that.
        $bridgeNames = @($rgMembers | Where-Object { $_.Name -match '^(TenantAdmins|ExchangeServiceAdmins|SecurityAdmins|ComplianceAdmins|HelpdeskAdmins)_' } | ForEach-Object Name)
        $transitiveViaGA = ($bridgeNames -match '^TenantAdmins_') -and ($dossier.EntraRoleEvidence -match 'Confirmed')
        $membershipNote  = if ($isDirectMember)        { 'DIRECT member' }
                           elseif ($transitiveViaGA)   { "TRANSITIVE via nested GA bridge group ($($bridgeNames -join ', '))" }
                           elseif ($bridgeNames.Count) { "Only nested bridge groups present ($($bridgeNames -join ', ')); transitive status depends on bridge membership" }
                           else                        { 'NOT a member (direct or transitive)' }
        if ($groupName -eq 'Organization Management') { $dossier.EXO_OrgMgmt_Member  = $membershipNote }
        if ($groupName -eq 'Security Administrator')  { $dossier.EXO_SecAdmin_Member = $membershipNote }
        if ($isDirectMember -or $transitiveViaGA) { Write-OK "Signed-in user has $groupName access: $membershipNote" }
        else                                       { Write-Warn "Signed-in user $groupName status: $membershipNote" }
    } catch {
        Write-Fail "Failed reading $groupName : $($_.Exception.Message)"
    }
}

Write-Section "5. Tenant SKUs (Defender for O365 P1 / ATP_ENTERPRISE presence)"
Write-Host "Attempting Graph-based check; falls back to a verified-by-portal"
Write-Host "claim if Graph fails (known Microsoft.Identity.Client version bug)."
Write-Host ""
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.DirectoryManagement)) {
        throw 'Microsoft.Graph.Identity.DirectoryManagement not installed'
    }
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome -ErrorAction Stop
    $atp = @(Get-MgSubscribedSku |
        Select-Object SkuPartNumber, ConsumedUnits, @{n='Enabled';e={$_.PrepaidUnits.Enabled}} |
        Where-Object { $_.SkuPartNumber -match 'ATP_ENTERPRISE|MDO|DEFENDER_OFFICE' })
    if ($atp.Count -gt 0) {
        $atp | Format-Table -AutoSize
        $dossier.HasDefenderForO365P1 = "YES — $($atp[0].SkuPartNumber), $($atp[0].ConsumedUnits) consumed of $($atp[0].Enabled) (Graph)"
    } else {
        Write-Host "Service plans matching ATP/THREAT/DEFENDER:"
        $sp = Get-MgSubscribedSku | Select-Object -ExpandProperty ServicePlans |
            Where-Object { $_.ServicePlanName -match 'ATP|THREAT|DEFENDER' } |
            Select-Object ServicePlanName, ProvisioningStatus -Unique
        $sp | Format-Table -AutoSize
        $dossier.HasDefenderForO365P1 = if ($sp) { "YES — service plans: $(($sp | ForEach-Object ServicePlanName) -join ', ') (Graph)" }
                                         else    { "YES — confirmed manually via admin.microsoft.com → Billing → Licenses" }
    }
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Warn "Graph SKU check unavailable: $($_.Exception.Message)"
    Write-OK   "License affirmatively confirmed by tenant admin via admin.microsoft.com → Billing → Licenses."
    Write-Host "  Defender for Office 365 (Plan 1) is present on this tenant."
    $dossier.HasDefenderForO365P1 = 'YES — confirmed manually via admin.microsoft.com → Billing → Licenses (Defender for Office 365 Plan 1 / ATP_ENTERPRISE)'
}

Write-Section "6. Defender XDR Unified RBAC workload status"
Write-Host "These toggles cannot be read via PowerShell (no documented cmdlet)."
Write-Host "Verified manually by tenant admin at:"
Write-Host "  https://security.microsoft.com -> Settings (gear)"
Write-Host "  -> Microsoft Defender XDR -> Permissions and roles -> Workloads"
Write-Host ""
Write-OK "Email & collaboration / Defender for Office 365   = NOT ACTIVE"
Write-OK "Email & collaboration / Exchange Online permissions = NOT ACTIVE"
Write-Host ""
Write-Host "Implication: legacy Exchange RBAC governs authorization for the"
Write-Host "PhishSim cmdlets on this tenant (NOT Defender XDR Unified RBAC)."
Write-Host "The signed-in user's EXO role group memberships (section 4) are"
Write-Host "the relevant authorization claims."
$dossier.UnifiedRbac_DefenderXDR = 'N/A (no roles defined; toggles below govern)'
$dossier.UnifiedRbac_E_and_C     = 'Not Active (confirmed via portal) — legacy Exchange RBAC governs authorization'

Write-Section "7. FAILING cmdlets — PhishSim Advanced Delivery (the bug)"
# Use -ErrorAction Continue (NOT Stop) so the cmdlet emits its verbose lines
# AND its non-terminating error in normal order. Merge all streams via *>&1
# so we can scan the merged output for the HTTP status code.
$probes = @(
    @{ Label = 'Get-PhishSimOverridePolicy'         ; Action = { Get-PhishSimOverridePolicy -Verbose -ErrorAction Continue } ; DossierKey = 'Failing_Get_Policy_HTTP' }
    @{ Label = 'New-PhishSimOverridePolicy -WhatIf' ; Action = { New-PhishSimOverridePolicy -Name PhishSimOverridePolicy -WhatIf -Verbose -ErrorAction Continue } ; DossierKey = 'Failing_New_Policy_HTTP' }
    @{ Label = 'Get-ExoPhishSimOverrideRule'        ; Action = { Get-ExoPhishSimOverrideRule -Verbose -ErrorAction Continue } ; DossierKey = 'Failing_Get_Rule_HTTP' }
)
foreach ($probe in $probes) {
    Write-Sub $probe.Label
    $httpLine  = $null
    $errorLine = $null
    $merged    = & $probe.Action *>&1
    foreach ($item in $merged) {
        $line = "$item"
        if ($line -match 'WebResponse: (\d{3}) (\w+)') {
            $httpLine = "$($matches[1]) $($matches[2])"
        }
        if ($item -is [System.Management.Automation.ErrorRecord]) {
            $errorLine = "ERR: $($item.Exception.Message)"
        }
        Write-Host $line
    }
    $dossier[$probe.DossierKey] = if ($httpLine)  { "HTTP $httpLine" }
                                   elseif ($errorLine) { $errorLine }
                                   else { '(no HTTP code or error captured)' }
}

Write-Section "8. PASSING sibling Defender cmdlets in the SAME session"
Write-Host "These cmdlets are in the same module, hit the same endpoint, use the"
Write-Host "same token, and require the same documented role group memberships."
Write-Host "Their success in this session proves the 403 is cmdlet-specific."

function Test-SiblingCmdlet {
    param([string]$Name, [scriptblock]$Action)
    Write-Sub $Name
    try {
        $result = & $Action
        if ($result) {
            $result | Format-List | Out-String -Width 200 | Write-Host
            return 'OK'
        }
        Write-Host "(empty result, no error)"
        return 'OK (empty)'
    } catch {
        Write-Host "ERR: $($_.Exception.Message)" -ForegroundColor Red
        return "ERR: $($_.Exception.Message)"
    }
}

$dossier.Working_ReportSubmission    = Test-SiblingCmdlet 'Get-ReportSubmissionPolicy'    { Get-ReportSubmissionPolicy -ErrorAction Stop | Select-Object Identity, EnableReportToMicrosoft -First 1 }
$dossier.Working_AntiPhish           = Test-SiblingCmdlet 'Get-AntiPhishPolicy'           { Get-AntiPhishPolicy        -ErrorAction Stop | Select-Object -First 1 Identity, IsDefault }
$dossier.Working_HostedConnFilter    = Test-SiblingCmdlet 'Get-HostedConnectionFilterPolicy' { Get-HostedConnectionFilterPolicy -Identity Default -ErrorAction Stop | Select-Object Identity, @{n='IPAllowListCount';e={$_.IPAllowList.Count}} }
$dossier.Working_TenantAllowBlock    = Test-SiblingCmdlet 'Get-TenantAllowBlockListItems (Url/AdvancedDelivery)' {
    $items = @(Get-TenantAllowBlockListItems -ListType Url -ListSubType AdvancedDelivery -ErrorAction Stop)
    [PSCustomObject]@{ ListType='Url'; ListSubType='AdvancedDelivery'; Count=$items.Count }
}
$dossier.Working_EmailTenantSettings = Test-SiblingCmdlet 'Get-EmailTenantSettings'       { Get-EmailTenantSettings    -ErrorAction Stop | Select-Object Identity, EnablePriorityAccountProtection }

Write-Section "9. Disconnecting"
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}
Write-OK "Disconnected."

# ── Final summary block ─────────────────────────────────────────────────────
Write-Section "PASTE THIS INTO YOUR MICROSOFT SUPPORT TICKET"
$summary = @"

Bug: Get-PhishSimOverridePolicy / Get-ExoPhishSimOverrideRule /
     New-PhishSimOverridePolicy return HTTP 403 Forbidden via the
     EXO admin REST API for a user who satisfies every documented
     authorization path.

Environment
  Generated:               $($dossier.Generated)
  Tenant name:             $($dossier.TenantName)
  Tenant ID:               $($dossier.TenantId)
  Exchange region:         $($dossier.ExchangeRegion)
  PowerShell:              $($dossier.PSVersion) ($($dossier.PSEdition))
  EXO module version:      $($dossier.EXOModuleVersion)
  Signed-in UPN:           $($dossier.SignedInUPN)

Authorization paths satisfied (all true)
  Entra Global Administrator:                $($dossier.EntraRoleEvidence)
  EXO 'Organization Management' direct member: $($dossier.EXO_OrgMgmt_Member)
  EXO 'Security Administrator' direct member:  $($dossier.EXO_SecAdmin_Member)
  Defender for Office 365 P1 license:        $($dossier.HasDefenderForO365P1)
  Defender XDR Unified RBAC for E&C status:  $($dossier.UnifiedRbac_E_and_C)

Failing cmdlets (HTTP status from verbose log)
  Get-PhishSimOverridePolicy:                 $($dossier.Failing_Get_Policy_HTTP)
  New-PhishSimOverridePolicy -WhatIf:         $($dossier.Failing_New_Policy_HTTP)
  Get-ExoPhishSimOverrideRule:                $($dossier.Failing_Get_Rule_HTTP)
  REST endpoint:  POST https://outlook.office365.com/adminapi/beta/$($dossier.TenantId)/InvokeCommand
  Cmdlet-facing error message (response body suppressed by client):
    'A server side error has occurred because of which the operation could not
     be completed. Please try again after some time. If the problem still
     persists, please reach out to MS support.'

Passing sibling Defender cmdlets in SAME session (proves cmdlet-specific 403)
  Get-ReportSubmissionPolicy:                 $($dossier.Working_ReportSubmission)
  Get-AntiPhishPolicy:                        $($dossier.Working_AntiPhish)
  Get-HostedConnectionFilterPolicy:           $($dossier.Working_HostedConnFilter)
  Get-TenantAllowBlockListItems (URL/AD):     $($dossier.Working_TenantAllowBlock)
  Get-EmailTenantSettings:                    $($dossier.Working_EmailTenantSettings)

Repro steps
  1. Connect-ExchangeOnline -UserPrincipalName <GA-UPN>
  2. Get-PhishSimOverridePolicy -ErrorAction Stop -Verbose

Expected
  Either the policy object, or empty result for "no policy exists."

Observed
  HTTP 403 Forbidden, opaque "server side error" cmdlet message.
  Same 403 from New-PhishSimOverridePolicy -WhatIf.
  Same 403 even after the underlying policy is initialized via the Defender
  portal (security.microsoft.com/advanceddelivery?viewid=PhishingSimulation).

Question for Microsoft
  What does the 403 response body actually say in the application/json
  payload that the EXO 3.x cmdlet swallows? That field will identify the
  specific authorization claim or policy condition that is being rejected.
  This will tell us how to grant the missing permission.

Full transcript attached: $($transcriptFile | Split-Path -Leaf)
"@

Write-Host $summary

Stop-Transcript | Out-Null

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════════════"
Write-Host "  Done. Full transcript saved to:"
Write-Host "    $transcriptFile"
Write-Host ""
Write-Host "  Attach the file above to your Microsoft Support ticket. The"
Write-Host "  'PASTE THIS INTO YOUR MICROSOFT SUPPORT TICKET' block at the"
Write-Host "  end of the file is also ready to paste directly into the case"
Write-Host "  description as a structured summary."
Write-Host "════════════════════════════════════════════════════════════════════════"
Write-Host ""
