<#
.SYNOPSIS
    Creates standard admin accounts on a Microsoft 365 tenant.

.DESCRIPTION
    Launched with no switch, the script first shows an interactive action menu so
    the operator can choose what to do:

        1. New account setup      - provision all four standard accounts + CA policy
        2. Create individual      - create a subset of the four standard accounts
        3. Create a NEW custom     - an operator-named account that mimics the role
                                     profile of one archetype (breakglass GA,
                                     adm-engineer, or adm-support)
        4. Reset password(s)      - reset by typed UPN (breakglass always excluded)

    The -ResetPasswords and -WhatIf switches bypass the menu for non-interactive use.

    Connects to a Microsoft 365 tenant via Microsoft Graph and provisions four
    standard admin accounts using the tenant's *.onmicrosoft.com domain:

        adm-breakglass-msp@<tenant>.onmicrosoft.com
            Global Administrator - MSP-held breakglass emergency account.
            Excluded from ALL Conditional Access policies.
            Credentials stored in MSP secure vault. Never used for day-to-day work.

        adm-breakglass-client@<tenant>.onmicrosoft.com
            Global Administrator - Client-held breakglass emergency account.
            Excluded from ALL Conditional Access policies.
            Credentials handed to client and stored in a physically separate location
            from the MSP copy. Ensures client retains independent emergency access.

        adm-engineer@<tenant>.onmicrosoft.com
            Engineer account for day-to-day tenant work.
            Holds a curated set of built-in Entra ID roles ("Tier 1" - operational).
            Explicitly excludes elevation-capable roles (Conditional Access Admin,
            Privileged Role Admin, Application Admin, Privileged Auth Admin, etc.) -
            those are listed in the script's "Tier 0.5" comment block as PIM-eligible
            candidates the operator can configure separately when PIM is set up.
            Subject to MFA via CA policy.

        adm-support@<tenant>.onmicrosoft.com
            Support Admin - Exchange, User, Helpdesk, SharePoint, and License Admin roles.
            Subject to MFA via CA policy.

    A Conditional Access policy is created requiring MFA for adm-engineer and
    adm-support. Both breakglass accounts are excluded from all CA policies.

    If an account already exists it is skipped with a warning. Credentials for
    newly created accounts are displayed in the console - copy them immediately
    and store securely.

.PARAMETER ResetPasswords
    Bypasses the menu and resets the passwords for adm-engineer and adm-support
    only (the same fixed targets as before this switch gained a menu). Neither
    breakglass account is ever touched. New passwords are displayed in the console
    - copy them immediately. Skips all account creation, role, and CA policy steps.

.PARAMETER WhatIf
    Shows what would be created/changed without making any changes. Can also be
    toggled from within the interactive menu.

.EXAMPLE
    .\New-TenantAdminAccounts.ps1

    Shows the interactive action menu, then connects. If you are already signed in
    to Microsoft Graph in the current session, that connection (and tenant) is
    reused automatically. Otherwise a browser sign-in prompt appears - whichever
    tenant you authenticate against is used. No tenant ID needed.

.EXAMPLE
    .\New-TenantAdminAccounts.ps1 -ResetPasswords

    Skips the menu and resets passwords for adm-engineer and adm-support on the
    connected tenant. Breakglass accounts are not touched. To reset a different
    account, use the menu's "Reset password(s)" action and type the UPN.

.NOTES
    Requires the Microsoft.Graph PowerShell module:
        Install-Module Microsoft.Graph -Scope CurrentUser

    All accounts are created without a usageLocation, which prevents license
    assignment in Entra ID. This is intentional - admin accounts should have no
    mailbox, OneDrive, or Teams presence to reduce their attack surface.

    Graph API delegated permissions required:
        User.ReadWrite.All
        RoleManagement.ReadWrite.Directory
        Policy.ReadWrite.ConditionalAccess
        Policy.Read.All
        Domain.Read.All

    Requires PowerShell 7.1 or later.
#>

#Requires -Version 7.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$ResetPasswords
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region -- Output Helpers -----------------------------------------------------

function Write-Step { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "   [OK]  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "   [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "   [XX]  $Msg" -ForegroundColor Red }

#endregion

#region -- Interactive Action Menu --------------------------------------------
#
#  Shown only when the script is launched with no switch. Lets the operator pick
#  what to do instead of the script assuming "full setup". Raw-mode arrow-key TUI
#  with a plain Read-Host fallback for redirected input / no virtual terminal.
#  (Mirrors the Show-UpdateMenu pattern in Update-BreakglassAlertEmail.ps1.)
#
#  Returns a hashtable:
#     @{ Action   = 'Setup' | 'CreateSelected' | 'CreateCustom' | 'Reset'
#        Accounts = @(<mailNickname>, ...)   # populated for CreateSelected only
#        WhatIf   = $bool }
#  ...or $null if the operator cancels (esc / no valid choice).

# The four standard accounts, keyed by mailNickname, with a short description.
$StandardAccounts = [ordered]@{
    'adm-breakglass-msp'    = 'Breakglass, MSP-held    (Global Admin, excluded from CA)'
    'adm-breakglass-client' = 'Breakglass, client-held (Global Admin, excluded from CA)'
    'adm-engineer'          = 'Engineer (all built-in roles except GA, MFA required)'
    'adm-support'           = 'Support  (Exchange/User/Helpdesk/SharePoint/License, MFA)'
}

function Show-ActionMenuFallback {
    [OutputType([hashtable])]
    param()

    Write-Host ""
    Write-Host "  NEW-TENANTADMINACCOUNTS" -ForegroundColor Cyan
    Write-Host "  ----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1) New account setup      - all four standard accounts + CA policy"
    Write-Host "  2) Create individual      - pick which standard account(s) to create"
    Write-Host "  3) Create a NEW custom    - operator-named account using a role template"
    Write-Host "  4) Reset password(s)      - reset by typed UPN (breakglass excluded)"
    Write-Host ""
    $choice = (Read-Host "  Choose an action [1-4]").Trim()

    $map = @{ '1' = 'Setup'; '2' = 'CreateSelected'; '3' = 'CreateCustom'; '4' = 'Reset' }
    $act = $map[$choice]
    if (-not $act) { Write-Warn "No valid action chosen."; return $null }

    $accounts = @()
    if ($act -eq 'CreateSelected') {
        Write-Host ""
        $accKeys = @($StandardAccounts.Keys)
        for ($i = 0; $i -lt $accKeys.Count; $i++) {
            Write-Host "     $($i + 1)) $($accKeys[$i])  - $($StandardAccounts[$accKeys[$i]])"
        }
        $raw = (Read-Host "  Accounts to create (e.g. 3,4  or  'all')").Trim()
        if ($raw -match '^(?i)all$') {
            $accounts = $accKeys
        }
        else {
            $accounts = @(
                $raw -split '[,\s]+' | Where-Object { $_ -ne '' } | ForEach-Object {
                    if ($_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $accKeys.Count) { $accKeys[[int]$_ - 1] }
                    elseif ($_ -in $accKeys) { $_ }
                }
            )
        }
        if ($accounts.Count -eq 0) { Write-Warn "No accounts selected."; return $null }
    }

    Write-Host ""
    $wi = (Read-Host "  WhatIf - dry run, no changes? [y/N]") -match '^[yY]'
    Write-Host ""

    return @{ Action = $act; Accounts = @($accounts); WhatIf = $wi }
}

function Show-ActionMenu {
    [OutputType([hashtable])]
    param()

    $rawOk = $false
    try { $rawOk = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsInputRedirected } catch {}
    if (-not $rawOk) { return Show-ActionMenuFallback }

    $ESC = [char]27

    $actionLabels = @(
        'New account setup            (all four standard accounts + CA policy)',
        'Create individual account(s) (pick from the four standard accounts)',
        'Create a NEW custom account  (operator-named, choose a role template)',
        'Reset password(s)            (by typed UPN - breakglass excluded)'
    )
    $accKeys = @($StandardAccounts.Keys)

    # ── Mutable state ─────────────────────────────────────────────────────────
    #  The highlighted row IS the selected action (radio follows the cursor), so
    #  up/down chooses and Enter runs - no separate "select" keypress. The account
    #  checkboxes (multi-select) still toggle with Space, and WhatIf toggles with W.
    $accSel    = @{}
    foreach ($k in $accKeys) { $accSel[$k] = $false }
    $whatIf    = $false
    $focusKey  = 'a0'                    # semantic focus - resolved to an index each render
    $done      = $false
    $cancel    = $false
    $lineCount = 0
    $isFirst   = $true
    $hint      = ''

    [Console]::Write("$ESC[?25l")        # hide cursor

    try {
        while ($true) {

            # Selected action is derived from the focused row: an action row selects
            # itself; an account checkbox belongs to CreateSelected (action 1).
            $selAction = if ($focusKey -like 'a?') { [int]$focusKey.Substring(1) }
                         elseif ($focusKey -like 'c:*') { 1 }
                         else { 0 }

            # Ordered list of focusable rows (accounts appear only under CreateSelected).
            # WhatIf is intentionally NOT here - it is a W hotkey so reaching it never
            # moves the action selection.
            $keys = [System.Collections.Generic.List[string]]::new()
            $keys.Add('a0'); $keys.Add('a1')
            if ($selAction -eq 1) { foreach ($k in $accKeys) { $keys.Add("c:$k") } }
            $keys.Add('a2'); $keys.Add('a3')
            if ($keys.IndexOf($focusKey) -lt 0) { $focusKey = 'a1' }

            $ptr = { param([string]$k) if ($focusKey -eq $k) { "$ESC[97m>$ESC[0m" } else { ' ' } }
            $rb  = { param([bool]$on)  if ($on) { "$ESC[92m(o)$ESC[0m" } else { '( )' } }
            $cb  = { param([bool]$on)  if ($on) { "$ESC[92m[x]$ESC[0m" } else { '[ ]' } }

            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add("")
            $lines.Add("  $ESC[96;1mNEW-TENANTADMINACCOUNTS$ESC[0m")
            $lines.Add("  $ESC[90m--------------------------------------------------------------$ESC[0m")
            $lines.Add("")
            $lines.Add("  $ESC[90mA browser sign-in window will open when you press Enter.$ESC[0m")
            $lines.Add("")
            $lines.Add("  $ESC[90mCHOOSE AN ACTION$ESC[0m")
            for ($i = 0; $i -lt 4; $i++) {
                $aKey   = "a$i"
                $colour = if ($selAction -eq $i) { "$ESC[97m" } else { "$ESC[37m" }
                $lines.Add(" $(& $ptr $aKey) $(& $rb ($selAction -eq $i))  $colour$($actionLabels[$i])$ESC[0m")
                if ($i -eq 1 -and $selAction -eq 1) {
                    foreach ($k in $accKeys) {
                        $lines.Add("       $(& $ptr "c:$k") $(& $cb $accSel[$k])  $ESC[37m$k$ESC[0m  $ESC[90m$ESC[2m$($StandardAccounts[$k])$ESC[0m")
                    }
                }
            }
            $lines.Add("")
            $lines.Add("  $ESC[90mOPTIONS$ESC[0m")
            $lines.Add("     $(& $cb $whatIf)  $ESC[37mWhatIf$ESC[0m  $ESC[90m$ESC[2m(press W - dry run, no changes made)$ESC[0m")
            $lines.Add("")
            $lines.Add("  $ESC[90m--------------------------------------------------------------$ESC[0m")
            if ($hint) {
                $lines.Add("  $ESC[93m$hint$ESC[0m")
            }
            elseif ($selAction -eq 1) {
                $lines.Add("  $ESC[90m  up/down move   space tick account   w WhatIf   enter run   esc cancel$ESC[0m")
            }
            else {
                $lines.Add("  $ESC[90m  up/down move & select   w WhatIf   enter run   esc cancel$ESC[0m")
            }
            $lines.Add("")

            # Reposition to the top of the block and clear everything below before
            # repainting. Clearing to end-of-screen ($ESC[0J) is essential because the
            # block height changes when the account checkboxes show/hide - without it,
            # shrinking a render leaves stale lines (e.g. a duplicate footer) behind.
            if (-not $isFirst) { [Console]::Write("$ESC[$($lineCount)A$ESC[0J") }
            foreach ($ln in $lines) { [Console]::WriteLine($ln) }
            $lineCount = $lines.Count
            $isFirst   = $false

            if ($done -or $cancel) { break }

            $key = $null
            try { $key = [Console]::ReadKey($true) } catch { $cancel = $true; continue }
            $hint = ''
            $idx  = $keys.IndexOf($focusKey)

            switch ($key.Key) {
                ([ConsoleKey]::UpArrow)   { $idx = [Math]::Max(0, $idx - 1); $focusKey = $keys[$idx] }
                ([ConsoleKey]::DownArrow) { $idx = [Math]::Min($keys.Count - 1, $idx + 1); $focusKey = $keys[$idx] }
                ([ConsoleKey]::Spacebar)  {
                    # Space toggles the highlighted account checkbox (multi-select).
                    if ($focusKey -like 'c:*') { $k = $focusKey.Substring(2); $accSel[$k] = -not $accSel[$k] }
                }
                ([ConsoleKey]::W)         { $whatIf = -not $whatIf }
                ([ConsoleKey]::Enter)     {
                    if ($selAction -eq 1 -and -not ($accSel.Values -contains $true)) {
                        $hint = 'Tick at least one account (space), or move to another action.'
                    }
                    else { $done = $true }
                }
                ([ConsoleKey]::Escape)    { $cancel = $true }
            }
        }
    }
    finally {
        [Console]::Write("$ESC[?25h")     # restore cursor
    }

    if ($cancel) { return $null }

    # Resolve the final selected action from the last focused row.
    $finalAction = if ($focusKey -like 'a?') { [int]$focusKey.Substring(1) }
                   elseif ($focusKey -like 'c:*') { 1 }
                   else { 0 }
    $selectedAccounts = @($accKeys | Where-Object { $accSel[$_] })
    $actMap = @('Setup', 'CreateSelected', 'CreateCustom', 'Reset')
    return @{
        Action   = $actMap[$finalAction]
        Accounts = $selectedAccounts
        WhatIf   = $whatIf
    }
}

#endregion

#region -- Prerequisites ------------------------------------------------------

Write-Step "Checking prerequisites..."

$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Identity.SignIns'
)

$missing = $requiredModules | Where-Object { -not (Get-Module -ListAvailable -Name $_) }

if ($missing) {
    Write-Fail "Missing PowerShell modules:"
    $missing | ForEach-Object { Write-Host "     - $_" -ForegroundColor Red }
    Write-Host "`n   Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

Write-OK "All required modules present"

#endregion

#region -- Role Template IDs --------------------------------------------------
#  Used for the Breakglass (GA) and Support account role assignments.

$RoleTemplateId = @{
    GlobalAdministrator     = '62e90394-69f5-4237-9190-012177145e10'
    ExchangeAdministrator   = '29232cdf-9323-42fd-ade2-1d097af3e4de'
    UserAdministrator       = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
    HelpdeskAdministrator   = '729827e3-9c14-49f7-bb1b-9608f156bbb8'
    SharePointAdministrator = 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c'
    LicenseAdministrator    = '4d6ac14f-3453-41d0-bef9-a3e0c569773a'
}

#endregion

#region -- Engineer Role Definitions (Tier 1 - operational) -------------------
#
#  Curated set of built-in Entra ID roles assigned to adm-engineer at provisioning.
#  This is the "Tier 1" / operational set - day-to-day admin work that does NOT
#  give the holder a path to elevate themselves or other identities.
#
#  Originally retrieved from tenant contoso.onmicrosoft.com on 2026-04-24,
#  then curated on 2026-05-04 to remove elevation-capable and system-reserved
#  roles. To refresh the canonical list of all built-in roles for re-curation:
#      Get-MgRoleManagementDirectoryRoleDefinition -Filter 'isBuiltIn eq true' -All |
#          Where-Object { $_.Id -ne '62e90394-69f5-4237-9190-012177145e10' } |
#          Sort-Object DisplayName |
#          ForEach-Object { "'$($_.DisplayName)' = '$($_.Id)'" }
#
# ------------------------------------------------------------------------------
#  TIER 0.5 - elevation-capable roles INTENTIONALLY excluded from this hash
# ------------------------------------------------------------------------------
#  These roles can grant other directory roles, modify identity-protection
#  policies, or bypass MFA. Standing assignment of any of them on a daily-use
#  account effectively turns it into Global Admin via a side door. Recommended
#  posture: configure each as PIM-eligible (NOT active) on adm-engineer in a
#  separate post-provisioning step, requiring activation + MFA + justification
#  + time-bound expiry. Requires Entra ID P2 license on the user.
#
#       Application Administrator                            (consent grants -> SP w/ RoleManagement.ReadWrite.Directory)
#       Authentication Extensibility Administrator           (custom auth code -> elevation)
#       Authentication Extensibility Password Administrator
#       Authentication Policy Administrator                  (tenant-wide MFA / passwordless policies)
#       Cloud Application Administrator                      (same risk as Application Administrator)
#       Conditional Access Administrator                     (can carve self-bypass exceptions)
#       Domain Name Administrator                            (federation / identity takeover via DNS)
#       External Identity Provider Administrator             (rogue federation source)
#       Hybrid Identity Administrator                        (controls AD Connect)
#       Privileged Authentication Administrator              (resets MFA on other admins -> takeover)
#       Privileged Role Administrator                        (can grant any directory role to anyone)
#
# ------------------------------------------------------------------------------
#  Other roles INTENTIONALLY excluded (rare / deprecated / system-reserved)
# ------------------------------------------------------------------------------
#       Customer Delegated Admin Relationship Administrator  (CSP/GDAP partner-side - MSP rarely needs)
#       Partner Tier1 Support / Partner Tier2 Support        (deprecated Microsoft backdoor roles)
#       Tenant Creator                                       (creates new tenants under this account)
#       Tenant Governance Relationship Administrator/Reader  (CSP relationship management)
#       Directory Synchronization Accounts                   (reserved by Microsoft for AD Connect)
#       On Premises Directory Sync Account                   (reserved)
#       Device Join / Device Managers / Device Users /
#         Workplace Device Join                              (system roles - not user-assignable)
#       Guest User / Restricted Guest User / User            (membership types, not admin roles)
#

$EngineerRoleDefinitions = [ordered]@{
    'Agent ID Administrator'                              = 'db506228-d27e-4b7d-95e5-295956d6615f'
    'Agent ID Developer'                                  = 'adb2368d-a9be-41b5-8667-d96778e081b0'
    'Agent Registry Administrator'                        = '6b942400-691f-4bf0-9d12-d8a254a2baf5'
    'AI Administrator'                                    = 'd2562ede-74db-457e-a7b6-544e236ebb61'
    'AI Reader'                                           = '1fe13547-53f6-408d-ac04-7f8eed167b38'
    'Application Developer'                               = 'cf1c38e5-3621-4004-a7cb-879624dced7c'
    'Attack Payload Author'                               = '9c6df0f2-1e7c-4dc3-b195-66dfbd24aa8f'
    'Attack Simulation Administrator'                     = 'c430b396-e693-46cc-96f3-db01bf8bb62a'
    'Attribute Assignment Administrator'                  = '58a13ea3-c632-46ae-9ee0-9c0d43cd7f3d'
    'Attribute Assignment Reader'                         = 'ffd52fa5-98dc-465c-991d-fc073eb59f8f'
    'Attribute Definition Administrator'                  = '8424c6f0-a189-499e-bbd0-26c1753c96d4'
    'Attribute Definition Reader'                         = '1d336d2c-4ae8-42ef-9711-b3604ce3fc2c'
    'Attribute Log Administrator'                         = '5b784334-f94b-471a-a387-e7219fc49ca2'
    'Attribute Log Reader'                                = '9c99539d-8186-4804-835f-fd51ef9e2dcd'
    'Attribute Provisioning Administrator'                = 'ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe'
    'Attribute Provisioning Reader'                       = '422218e4-db15-4ef9-bbe0-8afb41546d79'
    'Authentication Administrator'                        = 'c4e39bd9-1100-46d3-8c65-fb160da0071f'
    'Azure AD Joined Device Local Administrator'          = '9f06204d-73c1-4d4c-880a-6edb90606fd8'
    'Azure DevOps Administrator'                          = 'e3973bdf-4987-49ae-837a-ba8e231c7286'
    'Azure Information Protection Administrator'          = '7495fdc4-34c4-4d15-a289-98788ce399fd'
    'B2C IEF Keyset Administrator'                        = 'aaf43236-0c0d-4d5f-883a-6955382ac081'
    'B2C IEF Policy Administrator'                        = '3edaf663-341e-4475-9f94-5c398ef6c070'
    'Billing Administrator'                               = 'b0f54661-2d74-4c50-afa3-1ec803f12efe'
    'Cloud App Security Administrator'                    = '892c5842-a9a6-463a-8041-72aa08ca3cf6'
    'Cloud Device Administrator'                          = '7698a772-787b-4ac8-901f-60d6b08affd2'
    'Compliance Administrator'                            = '17315797-102d-40b4-93e0-432062caca18'
    'Compliance Data Administrator'                       = 'e6d1a23a-da11-4be4-9570-befc86d067a7'
    'Customer LockBox Access Approver'                    = '5c4f9dcd-47dc-4cf7-8c9a-9e4207cbfc91'
    'Desktop Analytics Administrator'                     = '38a96431-2bdf-4b4c-8b6e-5d3d8abac1a4'
    'Directory Readers'                                   = '88d8e3e3-8f55-4a1e-953a-9b9898b8876b'
    'Directory Writers'                                   = '9360feb5-f418-4baa-8175-e2a00bac4301'
    'Dragon Administrator'                                = 'e93e3737-fa85-474a-aee4-7d3fb86510f3'
    'Dynamics 365 Administrator'                          = '44367163-eba1-44c3-98af-f5787879f96a'
    'Dynamics 365 Business Central Administrator'         = '963797fb-eb3b-4cde-8ce3-5878b3f32a3f'
    'Edge Administrator'                                  = '3f1acade-1e04-4fbc-9b69-f0302cd84aef'
    'Entra Backup Administrator'                          = 'b6a27b2b-f905-4b2e-81b5-0d90e0ef1fdb'
    'Entra Backup Reader'                                 = 'f42252d9-5400-4d7b-b9ef-cc582dbb8577'
    'Exchange Administrator'                              = '29232cdf-9323-42fd-ade2-1d097af3e4de'
    'Exchange Backup Administrator'                       = '49eb8f75-97e9-4e37-9b2b-6c3ebfcffa31'
    'Exchange Recipient Administrator'                    = '31392ffb-586c-42d1-9346-e59415a2cc4e'
    'Extended Directory User Administrator'               = 'dd13091a-6207-4fc0-82ba-3641e056ab95'
    'External ID User Flow Administrator'                 = '6e591065-9bad-43ed-90f3-e9424366d2f0'
    'External ID User Flow Attribute Administrator'       = '0f971eea-41eb-4569-a71e-57bb8a3eff1e'
    'Fabric Administrator'                                = 'a9ea8996-122f-4c74-9520-8edcd192826c'
    'Global Reader'                                       = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
    'Global Secure Access Administrator'                  = 'ac434307-12b9-4fa1-a708-88bf58caabc1'
    'Global Secure Access Log Reader'                     = '843318fb-79a6-4168-9e6f-aa9a07481cc4'
    'Groups Administrator'                                = 'fdd7a751-b60b-444a-984c-02652fe8fa1c'
    'Guest Inviter'                                       = '95e79109-95c0-4d8e-aee3-d01accf2d47b'
    'Helpdesk Administrator'                              = '729827e3-9c14-49f7-bb1b-9608f156bbb8'
    'Identity Governance Administrator'                   = '45d8d3c5-c802-45c6-b32a-1d70b5e1e86e'
    'Insights Administrator'                              = 'eb1f4a8d-243a-41f0-9fbd-c7cdf6c5ef7c'
    'Insights Analyst'                                    = '25df335f-86eb-4119-b717-0ff02de207e9'
    'Insights Business Leader'                            = '31e939ad-9672-4796-9c2e-873181342d2d'
    'Intune Administrator'                                = '3a2c62db-5318-420d-8d74-23affee5d9d5'
    'IoT Device Administrator'                            = '2ea5ce4c-b2d8-4668-bd81-3680bd2d227a'
    'Kaizala Administrator'                               = '74ef975b-6605-40af-a5d2-b9539d836353'
    'Knowledge Administrator'                             = 'b5a8dcf3-09d5-43a9-a639-8e29ef291470'
    'Knowledge Manager'                                   = '744ec460-397e-42ad-a462-8b3f9747a02c'
    'License Administrator'                               = '4d6ac14f-3453-41d0-bef9-a3e0c569773a'
    'Lifecycle Workflows Administrator'                   = '59d46f88-662b-457b-bceb-5c3809e5908f'
    'Message Center Privacy Reader'                       = 'ac16e43d-7b2d-40e0-ac05-243ff356ab5b'
    'Message Center Reader'                               = '790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b'
    'Microsoft 365 Backup Administrator'                  = '1707125e-0aa2-4d4d-8655-a7c786c76a25'
    'Microsoft 365 Migration Administrator'               = '8c8b803f-96e1-4129-9349-20738d9f9652'
    'Microsoft Graph Data Connect Administrator'          = 'ee67aa9c-e510-4759-b906-227085a7fd4d'
    'Microsoft Hardware Warranty Administrator'           = '1501b917-7653-4ff9-a4b5-203eaf33784f'
    'Microsoft Hardware Warranty Specialist'              = '281fe777-fb20-4fbb-b7a3-ccebce5b0d96'
    'Network Administrator'                               = 'd37c8bed-0711-4417-ba38-b4abe66ce4c2'
    'Office Apps Administrator'                           = '2b745bdf-0803-4d80-aa65-822c4493daac'
    'Organizational Branding Administrator'               = '92ed04bf-c94a-4b82-9729-b799a7a4c178'
    'Organizational Data Source Administrator'            = '9d70768a-0cbc-4b4c-aea3-2e124b2477f4'
    'Organizational Messages Approver'                    = 'e48398e2-f4bb-4074-8f31-4586725e205b'
    'Organizational Messages Writer'                      = '507f53e4-4e52-4077-abd3-d2e1558b6ea2'
    'Password Administrator'                              = '966707d0-3269-4727-9be2-8c3a10f19b9d'
    'People Administrator'                                = '024906de-61e5-49c8-8572-40335f1e0e10'
    'Permissions Management Administrator'                = 'af78dc32-cf4d-46f9-ba4e-4428526346b5'
    'Places Administrator'                                = '78b0ccd1-afc2-4f92-9116-b41aedd09592'
    'Power Platform Administrator'                        = '11648597-926c-4cf3-9c36-bcebb0ba8dcc'
    'Printer Administrator'                               = '644ef478-e28f-4e28-b9dc-3fdde9aa0b1f'
    'Printer Technician'                                  = 'e8cef6f1-e4bd-4ea8-bc07-4b8d950f4477'
    'Purview Workload Content Administrator'              = '3f04f91a-4ad7-4bd3-bcfa-49882ea1a88a'
    'Purview Workload Content Reader'                     = 'e07494ad-1654-4dd2-922e-6f81a71bf00f'
    'Purview Workload Content Writer'                     = '02d5655b-c1cf-4e5f-98da-5fb919085bf6'
    'Reports Reader'                                      = '4a5d8f65-41da-4de4-8968-e035b65339cf'
    'Search Administrator'                                = '0964bb5e-9bdb-4d7b-ac29-58e794862a40'
    'Search Editor'                                       = '8835291a-918c-4fd7-a9ce-faa49f0cf7d9'
    'Security Administrator'                              = '194ae4cb-b126-40b2-bd5b-6091b380977d'
    'Security Operator'                                   = '5f2222b1-57c3-48ba-8ad5-d4759f1fde6f'
    'Security Reader'                                     = '5d6b6bb7-de71-4623-b4af-96380a352509'
    'Service Support Administrator'                       = 'f023fd81-a637-4b56-95fd-791ac0226033'
    'SharePoint Administrator'                            = 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c'
    'SharePoint Advanced Management Administrator'        = '99009c4a-3b3f-4957-82a9-9d35e12db77e'
    'SharePoint Backup Administrator'                     = '9d3e04ba-3ee4-4d1b-a3a7-9aef423a09be'
    'SharePoint Embedded Administrator'                   = '1a7d78b6-429f-476b-b8eb-35fb715fffd4'
    'Skype for Business Administrator'                    = '75941009-915a-4869-abe7-691bff18279e'
    'Teams Administrator'                                 = '69091246-20e8-4a56-aa4d-066075b2a7a8'
    'Teams Communications Administrator'                  = 'baf37b3a-610e-45da-9e62-d9d1e5e8914b'
    'Teams Communications Support Engineer'               = 'f70938a0-fc10-4177-9e90-2178f8765737'
    'Teams Communications Support Specialist'             = 'fcf91098-03e3-41a9-b5ba-6f0ec8188a12'
    'Teams Devices Administrator'                         = '3d762c5a-1b6c-493f-843e-55a3b42923d4'
    'Teams External Collaboration Administrator'          = '2fe872fb-daa8-4afc-8f6c-53c4565cfef4'
    'Teams Reader'                                        = '1076ac91-f3d9-41a7-a339-dcdf5f480acc'
    'Teams Telephony Administrator'                       = 'aa38014f-0993-46e9-9b45-30501a20909d'
    'Tenant Governance Administrator'                     = '1981f584-96e9-4a6f-95b0-f522373f8fae'
    'Tenant Governance Reader'                            = 'e0a4caa6-fe82-443f-b92f-d87341d17b2e'
    'Usage Summary Reports Reader'                        = '75934031-6c7e-415a-99d7-48dbd49e875e'
    'User Administrator'                                  = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
    'User Experience Success Manager'                     = '27460883-1df1-4691-b032-3b79643e5e63'
    'Virtual Visits Administrator'                        = 'e300d9e7-4a2b-4295-9eff-f1c78b36cc98'
    'Viva Glint Tenant Administrator'                     = '0ec3f692-38d6-4d14-9e69-0377ca7797ad'
    'Viva Goals Administrator'                            = '92b086b3-e367-4ef2-b869-1de128fb986e'
    'Viva Pulse Administrator'                            = '87761b17-1ed2-4af3-9acd-92a150038160'
    'Windows 365 Administrator'                           = '11451d60-acb2-45eb-a7d6-43d0f0125c13'
    'Windows Update Deployment Administrator'             = '32696413-001a-46ae-978c-ce0f6b3620d2'
    'Yammer Administrator'                                = '810a2642-a034-447f-a5e8-41beaa378541'
}

#endregion

#region -- Password Generator -------------------------------------------------

function New-StrongPassword {
    [OutputType([string])]
    param([int]$Length = 24)

    $charSets = @(
        'ABCDEFGHJKLMNPQRSTUVWXYZ',   # uppercase (no I, O)
        'abcdefghjkmnpqrstuvwxyz',    # lowercase (no i, l, o)
        '23456789',                    # digits    (no 0, 1)
        '!@#$%^&*()-_=+'              # special
    )
    $all = -join $charSets
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    # Guarantee at least one character from every set
    $chars = [System.Collections.Generic.List[char]]::new()
    foreach ($set in $charSets) {
        $buf = [byte[]]::new(1)
        $rng.GetBytes($buf)
        $chars.Add($set[$buf[0] % $set.Length])
    }

    # Fill remaining length
    for ($i = $chars.Count; $i -lt $Length; $i++) {
        $buf = [byte[]]::new(1)
        $rng.GetBytes($buf)
        $chars.Add($all[$buf[0] % $all.Length])
    }

    # Fisher-Yates shuffle
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $buf = [byte[]]::new(1)
        $rng.GetBytes($buf)
        $j = $buf[0] % ($i + 1)
        $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
    }

    $rng.Dispose()
    return -join $chars
}

#endregion

#region -- Role Helpers -------------------------------------------------------

function Add-UserToDirectoryRole {
    <#
    .SYNOPSIS Assigns a built-in Entra ID role to a user using the unified RBAC API.
             Skips silently if the user already has the role.
    #>
    param(
        [string]$UserId,
        [string]$TemplateId,
        [string]$RoleName
    )

    # Check for existing assignment
    $existing = Get-MgRoleManagementDirectoryRoleAssignment `
        -Filter "principalId eq '$UserId' and roleDefinitionId eq '$TemplateId'" `
        -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Warn "   Already has role: $RoleName"
        return
    }

    New-MgRoleManagementDirectoryRoleAssignment `
        -PrincipalId    $UserId `
        -RoleDefinitionId $TemplateId `
        -DirectoryScopeId '/' | Out-Null

    Write-OK "   Role assigned: $RoleName"
}

#endregion

#region -- Determine Action ---------------------------------------------------
#
#  -ResetPasswords bypasses the menu (backward compatible - fixed engineer +
#  support targets, no prompt). Otherwise show the interactive action menu.

if ($ResetPasswords) {
    $action = @{ Action = 'Reset'; Accounts = @('adm-engineer', 'adm-support'); WhatIf = $false }
}
else {
    $action = Show-ActionMenu
    if ($null -eq $action) {
        Write-Host "`n[--] Cancelled. No changes made.`n" -ForegroundColor Cyan
        exit 0
    }
    if ($action.WhatIf) {
        $WhatIfPreference = $true
        Write-Warn "WhatIf mode selected - no changes will be made."
    }
}

#endregion

#region -- Connect to Microsoft Graph -----------------------------------------
#
#  Auto-detect strategy:
#    1. If a Graph session is already active (same PowerShell window, prior run),
#       check that it has all the required scopes and reuse it - no prompt.
#    2. Otherwise open a browser sign-in. Whichever tenant the admin authenticates
#       against becomes the working tenant. No TenantId parameter needed.

Write-Step "Connecting to Microsoft Graph..."

$requiredScopes = @(
    'User.ReadWrite.All',
    'RoleManagement.ReadWrite.Directory',
    'RoleManagement.Read.Directory',
    'Policy.ReadWrite.ConditionalAccess',
    'Policy.Read.All',
    'Domain.Read.All'
)

# Password resets use the authentication methods endpoint which requires this scope.
if ($action.Action -eq 'Reset') {
    $requiredScopes += 'UserAuthenticationMethod.ReadWrite.All'
}

# For password resets, always force a fresh token so the Directory.ReadWrite.All
# scope is actively consented rather than silently skipped from the MSAL cache.
if ($action.Action -eq 'Reset') {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
}

$ctx = Get-MgContext -ErrorAction SilentlyContinue

if ($ctx) {
    # Verify every required scope is present in the current token
    $missingScopes = @($requiredScopes | Where-Object { $_ -notin $ctx.Scopes })
    if ($missingScopes.Count -eq 0) {
        Write-OK "Reusing existing Graph session - Tenant: $($ctx.TenantId)  |  Account: $($ctx.Account)"
    }
    else {
        Write-Warn "Existing session is missing scopes ($($missingScopes -join ', ')) - reconnecting..."
        Disconnect-MgGraph | Out-Null
        Connect-MgGraph -Scopes $requiredScopes | Out-Null
        $ctx = Get-MgContext
        Write-OK "Connected - Tenant: $($ctx.TenantId)  |  Account: $($ctx.Account)"
    }
}
else {
    # No active session - browser prompt, tenant auto-detected from sign-in
    Connect-MgGraph -Scopes $requiredScopes | Out-Null
    $ctx = Get-MgContext
    Write-OK "Connected - Tenant: $($ctx.TenantId)  |  Account: $($ctx.Account)"
}

#endregion

#region -- Detect *.onmicrosoft.com Domain ------------------------------------

Write-Step "Detecting *.onmicrosoft.com domain..."

$omsDomains = Get-MgDomain |
    Where-Object { $_.Id -match '\.onmicrosoft\.com$' -and $_.Id -notmatch '\.mail\.onmicrosoft\.com$' }

if (-not $omsDomains) {
    Write-Fail "No *.onmicrosoft.com domain found in this tenant. Cannot continue."
    Disconnect-MgGraph | Out-Null
    exit 1
}

# Prefer the domain flagged as the initial (root) domain
$domain = ($omsDomains | Where-Object { $_.IsInitial }) ?? $omsDomains[0]

$domainName = $domain.Id                    # e.g. contoso.onmicrosoft.com
$tenantSlug = $domainName -replace '\.onmicrosoft\.com$', ''

Write-OK "Domain: $domainName"

#endregion

#region -- Password Reset (early exit) ----------------------------------------

if ($action.Action -eq 'Reset') {
    Write-Step "Reset passwords"

    # Switch path: fixed engineer + support targets. Menu path: prompt for UPNs.
    if ($ResetPasswords) {
        $resetTargets = @($action.Accounts | ForEach-Object { "$_@$domainName" })
    }
    else {
        Write-Host "  Enter one or more account UPNs to reset (space or comma separated)." -ForegroundColor DarkGray
        Write-Host "  A bare name (e.g. adm-support) is completed against this tenant." -ForegroundColor DarkGray
        Write-Host "  Press Enter to default to adm-engineer + adm-support." -ForegroundColor DarkGray
        $raw = (Read-Host "  UPNs").Trim()
        if ([string]::IsNullOrWhiteSpace($raw)) {
            $resetTargets = @("adm-engineer@$domainName", "adm-support@$domainName")
        }
        else {
            $resetTargets = @(
                $raw -split '[,\s]+' | Where-Object { $_ -ne '' } | ForEach-Object {
                    if ($_ -match '@') { $_ } else { "$_@$domainName" }
                }
            )
        }
    }

    $resetCredentials = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($upn in $resetTargets) {
        Write-Host "`n  -- $upn" -ForegroundColor White

        # Breakglass guard - emergency accounts are never reset by this script.
        if (($upn -split '@')[0] -match '^(?i)adm-breakglass-') {
            Write-Warn "Breakglass account - refusing to reset: $upn"
            continue
        }

        $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
        if (-not $user) {
            Write-Warn "Account not found - skipping: $upn"
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($upn, 'Reset password')) { continue }

        $newPassword = New-StrongPassword

        try {
            # Use the authentication methods endpoint rather than passwordProfile.
            # This is the correct admin reset path and bypasses the role-tier
            # protection that blocks passwordProfile updates for privileged accounts.
            # The password method GUID below is the well-known ID for cloud passwords.
            $pwMethodId = '28c10230-6103-485e-b985-444c60001490'

            Invoke-MgGraphRequest `
                -Method      POST `
                -Uri         "https://graph.microsoft.com/v1.0/users/$($user.Id)/authentication/passwordMethods/$pwMethodId/resetPassword" `
                -Body        (@{ newPassword = $newPassword } | ConvertTo-Json) `
                -ContentType 'application/json' `
                -ErrorAction Stop | Out-Null

            Write-OK "Password reset: $upn"
            $resetCredentials.Add([PSCustomObject]@{
                UserPrincipalName = $upn
                Password          = $newPassword
            })
        }
        catch {
            Write-Fail "Failed to reset password for $upn - $($_.Exception.Message)"
        }
    }

    if ($resetCredentials.Count -gt 0) {
        Write-Host ""
        Write-Host "  +----------------------------------------------------------+" -ForegroundColor Yellow
        Write-Host "  |      RESET CREDENTIALS - COPY NOW, STORE SECURELY       |" -ForegroundColor Yellow
        Write-Host "  +----------------------------------------------------------+" -ForegroundColor Yellow

        foreach ($cred in $resetCredentials) {
            Write-Host ""
            Write-Host "  UPN      : $($cred.UserPrincipalName)"
            Write-Host "  Password : " -NoNewline
            Write-Host $cred.Password -ForegroundColor Yellow -BackgroundColor DarkGray
            Write-Host "  ----------------------------------------------------------"
        }
        Write-Host ""
    }

    Disconnect-MgGraph | Out-Null
    Write-Host "`n[OK] Disconnected. Password reset complete.`n" -ForegroundColor Green
    exit 0
}

#endregion

#region -- Account Definitions ------------------------------------------------
#
#  Naming convention:
#    adm-<role-shortname>@<tenant>.onmicrosoft.com
#
#  adm-breakglass-msp    - GA Breakglass, MSP-held    (excluded from CA / MFA)
#  adm-breakglass-client - GA Breakglass, client-held (excluded from CA / MFA)
#  adm-engineer          - Engineer                   (MFA required)
#  adm-support           - Support Admin               (MFA required)

$accountDefs = @(
    [ordered]@{
        DisplayName       = 'ADM - Breakglass (MSP)'
        UserPrincipalName = "adm-breakglass-msp@$domainName"
        MailNickname      = 'adm-breakglass-msp'
        Description       = 'Global Admin Breakglass - MSP-held emergency account. Excluded from all Conditional Access policies. Credentials stored in MSP secure vault. Never used for day-to-day work.'
        Roles             = @('GlobalAdministrator')
        MfaRequired       = $false
        IsBreakglass      = $true
    },
    [ordered]@{
        DisplayName       = 'ADM - Breakglass (Client)'
        UserPrincipalName = "adm-breakglass-client@$domainName"
        MailNickname      = 'adm-breakglass-client'
        Description       = 'Global Admin Breakglass - client-held emergency account. Excluded from all Conditional Access policies. Credentials stored with client in a physically separate location from MSP copy. Never used for day-to-day work.'
        Roles             = @('GlobalAdministrator')
        MfaRequired       = $false
        IsBreakglass      = $true
    },
    [ordered]@{
        DisplayName              = 'ADM - Engineer'
        UserPrincipalName        = "adm-engineer@$domainName"
        MailNickname             = 'adm-engineer'
        # All built-in Entra ID roles are assigned dynamically at runtime except GA.
        # AllBuiltInRolesExceptGA flag triggers a live query of role definitions.
        Roles                    = @()
        AllBuiltInRolesExceptGA  = $true
        MfaRequired              = $true
    },
    [ordered]@{
        DisplayName       = 'ADM - Support'
        UserPrincipalName = "adm-support@$domainName"
        MailNickname      = 'adm-support'
        Description       = 'Support Admin - Exchange Admin, User Admin, Helpdesk Admin, SharePoint Admin, License Admin. MFA required.'
        Roles             = @(
            'ExchangeAdministrator',
            'UserAdministrator',
            'HelpdeskAdministrator',
            'SharePointAdministrator',
            'LicenseAdministrator'
        )
        MfaRequired       = $true
    }
)

#endregion

#region -- Select Accounts to Provision ---------------------------------------
#
#  Reduce $accountDefs to the set this run should create, based on the chosen
#  action. CreateCustom builds a synthetic def that clones a standard account's
#  role/MFA/breakglass shape but with an operator-supplied UPN and display name.

switch ($action.Action) {

    'Setup' {
        $selectedDefs = $accountDefs
    }

    'CreateSelected' {
        $selectedDefs = @($accountDefs | Where-Object { $_.MailNickname -in $action.Accounts })
        if ($selectedDefs.Count -eq 0) {
            Write-Fail "No matching accounts selected. Nothing to do."
            Disconnect-MgGraph | Out-Null
            exit 1
        }
    }

    'CreateCustom' {
        Write-Step "Define the new custom account"

        # Type only the name portion - the tenant's *.onmicrosoft.com domain is
        # appended automatically (a pasted full UPN has its domain replaced).
        Write-Host "  Enter only the name portion - it becomes:  <name>@$domainName" -ForegroundColor DarkGray

        $reserved = @('adm-breakglass-msp', 'adm-breakglass-client', 'adm-engineer', 'adm-support')

        # Local part -> UPN
        $localPart = $null
        while (-not $localPart) {
            $raw = (Read-Host "  New account name (local part, e.g. adm-jsmith)").Trim()
            if ([string]::IsNullOrWhiteSpace($raw)) { Write-Warn "Name cannot be empty."; continue }
            $raw = ($raw -replace '@.*$', '').ToLower()     # tolerate a pasted full UPN
            if ($raw -in $reserved) {
                Write-Warn "'$raw' is a standard account - use 'Create individual account(s)' instead."
                continue
            }
            if ($raw -notmatch '^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$') {
                Write-Warn "Invalid characters. Use letters, digits, dot, dash, underscore."
                continue
            }
            $localPart = $raw
        }
        $customUpn = "$localPart@$domainName"

        $dnRaw       = (Read-Host "  Display name (Enter for '$localPart')").Trim()
        $displayName = if ([string]::IsNullOrWhiteSpace($dnRaw)) { $localPart } else { $dnRaw }

        # Archetype whose role/MFA shape the new account should mimic
        Write-Host ""
        Write-Host "  Role template to mimic:" -ForegroundColor DarkGray
        Write-Host "    1) Breakglass GA  (Global Administrator, excluded from CA / MFA)"
        Write-Host "    2) adm-engineer   (all built-in roles except GA, MFA required)"
        Write-Host "    3) adm-support    (Exchange/User/Helpdesk/SharePoint/License, MFA required)"
        $archetype = $null
        while (-not $archetype) {
            switch ((Read-Host "  Choose template [1-3]").Trim()) {
                '1'     { $archetype = 'adm-breakglass-msp' }
                '2'     { $archetype = 'adm-engineer' }
                '3'     { $archetype = 'adm-support' }
                default { Write-Warn "Enter 1, 2, or 3." }
            }
        }

        # Clone the archetype's role/MFA/breakglass fields from the standard def so
        # the templates never drift from what full setup provisions.
        $template = $accountDefs | Where-Object { $_.MailNickname -eq $archetype } | Select-Object -First 1

        $customDef = [ordered]@{
            DisplayName       = $displayName
            UserPrincipalName = $customUpn
            MailNickname      = $localPart
            Description       = "Custom admin account provisioned from the '$archetype' role template."
            Roles             = $template.Roles
            MfaRequired       = $template.MfaRequired
        }
        if ($template['AllBuiltInRolesExceptGA']) { $customDef['AllBuiltInRolesExceptGA'] = $true }
        if ($template['IsBreakglass'])            { $customDef['IsBreakglass'] = $true }

        $selectedDefs = @($customDef)
        Write-OK "Custom account: $customUpn  (template: $archetype)"
    }
}

#endregion

#region -- Create Accounts & Assign Roles -------------------------------------

Write-Step "Provisioning accounts..."

# Tracks ObjectIds for use in the CA policy
$objectIdMap    = @{}   # UPN -> ObjectId
$newCredentials = [System.Collections.Generic.List[PSObject]]::new()

foreach ($def in $selectedDefs) {
    $upn = $def.UserPrincipalName
    Write-Host "`n  -- $($def.DisplayName)  ($upn)" -ForegroundColor White

    # Check for existing account
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Warn "Account already exists - skipping creation (ObjectId: $($existing.Id))"
        $objectIdMap[$upn] = $existing.Id
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($upn, 'Create user account')) { continue }

    # Create user
    $password = New-StrongPassword

    $userBody = @{
        displayName       = $def.DisplayName
        userPrincipalName = $upn
        mailNickname      = $def.MailNickname
        accountEnabled    = $true
        passwordProfile   = @{
            password                             = $password
            forceChangePasswordNextSignIn        = $false
            forceChangePasswordNextSignInWithMfa = $false
        }
        # usageLocation is intentionally omitted. Entra ID requires usageLocation
        # before any license can be assigned. Keeping it unset prevents these
        # purpose-built admin accounts from being licensed, reducing attack surface
        # (no mailbox, no OneDrive, no Teams presence to target).
    }

    $newUser = New-MgUser -BodyParameter $userBody
    Write-OK "Created: $upn  (ObjectId: $($newUser.Id))"

    $objectIdMap[$upn] = $newUser.Id

    # Assign roles
    if ($def['AllBuiltInRolesExceptGA']) {
        # Convert hard-coded role definitions into objects for the parallel block
        $rolesToAssign = @(
            $EngineerRoleDefinitions.GetEnumerator() | ForEach-Object {
                [PSCustomObject]@{ DisplayName = $_.Key; Id = $_.Value }
            }
        )
        Write-OK "$($rolesToAssign.Count) roles to assign - running in parallel (ThrottleLimit 10)..."

        # Capture userId for use inside parallel runspaces ($using: can't dot-reference objects)
        $parallelUserId = $newUser.Id

        $results = $rolesToAssign | ForEach-Object -ThrottleLimit 10 -Parallel {
            $roleDef = $_
            $userId  = $using:parallelUserId

            # Each parallel runspace needs its own module imports - auth context is shared
            Import-Module Microsoft.Graph.Authentication            -ErrorAction SilentlyContinue
            Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction SilentlyContinue
            Import-Module Microsoft.Graph.Identity.Governance       -ErrorAction SilentlyContinue

            try {
                New-MgRoleManagementDirectoryRoleAssignment `
                    -PrincipalId      $userId `
                    -RoleDefinitionId $roleDef.Id `
                    -DirectoryScopeId '/' `
                    -ErrorAction Stop | Out-Null
                [PSCustomObject]@{ OK = $true;  Name = $roleDef.DisplayName; Msg = $null }
            }
            catch {
                # 409 Conflict = role already assigned, not a real error
                if ($_.Exception.Message -match '409|Conflict|already') {
                    [PSCustomObject]@{ OK = $true;  Name = $roleDef.DisplayName; Msg = 'already assigned' }
                }
                else {
                    [PSCustomObject]@{ OK = $false; Name = $roleDef.DisplayName; Msg = $_.Exception.Message }
                }
            }
        }

        $okCount = @($results | Where-Object { $_.OK }).Count
        $failed  = @($results | Where-Object { -not $_.OK })
        Write-OK "$okCount / $($rolesToAssign.Count) roles assigned"
        foreach ($f in $failed) { Write-Warn "Failed: $($f.Name) - $($f.Msg)" }

        $rolesSummary = "All built-in roles except Global Administrator ($($rolesToAssign.Count) roles)"
    }
    else {
        foreach ($roleName in $def.Roles) {
            $templateId = $RoleTemplateId[$roleName]
            if (-not $templateId) {
                Write-Warn "Unknown role key '$roleName' - skipping"
                continue
            }
            Add-UserToDirectoryRole -UserId $newUser.Id -TemplateId $templateId -RoleName $roleName
        }
        $rolesSummary = $def.Roles -join ', '
    }

    $newCredentials.Add([PSCustomObject]@{
        DisplayName       = $def.DisplayName
        UserPrincipalName = $upn
        Password          = $password
        Roles             = $rolesSummary
        MfaRequired       = $def.MfaRequired
    })
}

#endregion

#region -- Conditional Access Policy ------------------------------------------
#
#  Best practice rationale:
#    - Breakglass MUST be excluded from every CA policy. It exists precisely to
#      recover access when normal auth paths (including MFA) are broken.
#    - A dedicated policy scoped to only these accounts is easier to audit and
#      avoids unintended scope creep from broader "all users" policies.
#    - Created in ENABLED state - MFA is enforced immediately on first sign-in
#      for adm-engineer and adm-support.

Write-Step "Ensuring Conditional Access MFA policy..."

# MFA targets = the MFA-required accounts provisioned in THIS run.
$mfaTargetIds = @(
    $selectedDefs |
        Where-Object { $_.MfaRequired } |
        ForEach-Object {
            $id = $objectIdMap[$_.UserPrincipalName]
            if ($id) { $id }
        }
)

# Breakglass exclusions = the two standard breakglass accounts (looked up by UPN
# so they are excluded even when this run didn't create them), plus any breakglass
# account created this run (e.g. a custom breakglass-template account).
$breakglassIds = [System.Collections.Generic.List[string]]::new()
foreach ($bgUpn in @("adm-breakglass-msp@$domainName", "adm-breakglass-client@$domainName")) {
    $bg = Get-MgUser -Filter "userPrincipalName eq '$bgUpn'" -ErrorAction SilentlyContinue
    if ($bg -and ($bg.Id -notin $breakglassIds)) { $breakglassIds.Add($bg.Id) }
}
foreach ($def in $selectedDefs) {
    if ($def['IsBreakglass']) {
        $id = $objectIdMap[$def.UserPrincipalName]
        if ($id -and ($id -notin $breakglassIds)) { $breakglassIds.Add($id) }
    }
}

if ($mfaTargetIds.Count -eq 0) {
    Write-Warn "No MFA-required accounts in this run - skipping CA policy."
}
else {
    $policyName = "Require MFA - Tenant Admin Accounts [$tenantSlug]"

    $existingPolicy = Get-MgIdentityConditionalAccessPolicy `
        -Filter "displayName eq '$policyName'" -ErrorAction SilentlyContinue

    if (-not $existingPolicy) {
        # Create fresh.
        if ($PSCmdlet.ShouldProcess($policyName, 'Create Conditional Access policy')) {
            $caBody = @{
                displayName   = $policyName
                state         = 'enabled'
                conditions    = @{
                    users = @{
                        includeUsers = [array]$mfaTargetIds
                        excludeUsers = $breakglassIds.Count -gt 0 ? [array]$breakglassIds : @()
                    }
                    applications = @{
                        includeApplications = @('All')
                    }
                    clientAppTypes = @('all')
                }
                grantControls = @{
                    operator        = 'OR'
                    builtInControls = @('mfa')
                }
            }

            $caPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $caBody
            Write-OK "Created CA policy: '$policyName'  (Id: $($caPolicy.Id))"
            Write-OK "MFA is enforced - the included admin accounts must use MFA to sign in."
        }
    }
    else {
        # Merge the new MFA targets into the existing policy, keep breakglass excluded.
        $curInclude = @($existingPolicy.Conditions.Users.IncludeUsers)
        $curExclude = @($existingPolicy.Conditions.Users.ExcludeUsers)
        $newInclude = @($curInclude + $mfaTargetIds  | Select-Object -Unique)
        $newExclude = @($curExclude + $breakglassIds | Select-Object -Unique)

        $addInclude = @($newInclude | Where-Object { $_ -notin $curInclude })
        $addExclude = @($newExclude | Where-Object { $_ -notin $curExclude })

        if ($addInclude.Count -eq 0 -and $addExclude.Count -eq 0) {
            Write-OK "CA policy '$policyName' already covers these accounts - no change."
        }
        elseif ($PSCmdlet.ShouldProcess($policyName, 'Update Conditional Access policy')) {
            $updateBody = @{
                conditions = @{
                    users = @{
                        includeUsers = [array]$newInclude
                        excludeUsers = [array]$newExclude
                    }
                }
            }
            Update-MgIdentityConditionalAccessPolicy `
                -ConditionalAccessPolicyId $existingPolicy.Id `
                -BodyParameter $updateBody | Out-Null
            Write-OK "Updated CA policy '$policyName' (+$($addInclude.Count) included, +$($addExclude.Count) excluded)."
        }
    }
}

#endregion

#region -- Credential Summary -------------------------------------------------

if ($newCredentials.Count -gt 0) {
    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |   NEW ACCOUNT CREDENTIALS - COPY NOW, STORE SECURELY    |" -ForegroundColor Yellow
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor Yellow

    foreach ($cred in $newCredentials) {
        Write-Host ""
        Write-Host "  Display Name  : $($cred.DisplayName)"
        Write-Host "  UPN           : $($cred.UserPrincipalName)"
        Write-Host "  Password      : " -NoNewline
        Write-Host $cred.Password -ForegroundColor Yellow -BackgroundColor DarkGray
        Write-Host "  Roles         : $($cred.Roles)"
        Write-Host "  MFA Required  : $($cred.MfaRequired)"
        Write-Host "  ----------------------------------------------------------"
    }

    if (@($selectedDefs | Where-Object { $_['IsBreakglass'] }).Count -gt 0) {
        Write-Host ""
        Write-Host "  [!!] BREAKGLASS storage:" -ForegroundColor Yellow
        Write-Host "       adm-breakglass-msp     -> MSP secure vault (offline, sealed). Do NOT" -ForegroundColor Yellow
        Write-Host "                                 store in a digital password manager that can" -ForegroundColor Yellow
        Write-Host "                                 be reached from the same auth chain you would" -ForegroundColor Yellow
        Write-Host "                                 need this account to recover." -ForegroundColor Yellow
        Write-Host "       adm-breakglass-client  -> Hand to client contact. Client stores in a" -ForegroundColor Yellow
        Write-Host "                                 physically separate location from the MSP copy" -ForegroundColor Yellow
        Write-Host "                                 (office safe, safety deposit box, etc.). Do NOT" -ForegroundColor Yellow
        Write-Host "                                 share with MSP or store digitally." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  [!!] Non-breakglass admin credentials -> MSP vault, against the client record." -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "`n   No new accounts were created (all already existed or WhatIf mode)." -ForegroundColor Cyan
}

#endregion

#region -- Disconnect ---------------------------------------------------------

Disconnect-MgGraph | Out-Null
Write-Host "`n[OK] Disconnected. Script complete.`n" -ForegroundColor Green

#endregion
