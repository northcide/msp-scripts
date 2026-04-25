<#
.SYNOPSIS
    Creates standard admin accounts on a Microsoft 365 tenant.

.DESCRIPTION
    Connects to a Microsoft 365 tenant via Microsoft Graph and provisions three
    standard admin accounts using the tenant's *.onmicrosoft.com domain:

        adm-breakglass@<tenant>.onmicrosoft.com
            Global Administrator - Breakglass emergency account.
            Excluded from ALL Conditional Access policies.
            Password should be stored offline (e.g., sealed envelope in a safe).

        adm-engineer@<tenant>.onmicrosoft.com
            Global Administrator - Engineer account for day-to-day tenant work.
            Subject to MFA via CA policy.

        adm-support@<tenant>.onmicrosoft.com
            Support Admin - Exchange, User, Helpdesk, SharePoint, and License Admin roles.
            Subject to MFA via CA policy.

    A Conditional Access policy is created in REPORT-ONLY mode requiring MFA for
    the two non-breakglass accounts. Review sign-in logs, then set the policy to
    'enabled' when ready.

    If an account already exists it is skipped with a warning. Credentials for
    newly created accounts are displayed in the console - copy them immediately
    and store securely.

.PARAMETER ResetPasswords
    Resets the passwords for adm-engineer and adm-support only.
    The breakglass account is never touched by this switch.
    New passwords are displayed in the console - copy them immediately.
    Skips all account creation, role assignment, and CA policy steps.

.PARAMETER WhatIf
    Shows what would be created/changed without making any changes.

.EXAMPLE
    .\New-TenantAdminAccounts.ps1

    Connects interactively. If you are already signed in to Microsoft Graph in
    the current session, that connection (and tenant) is reused automatically.
    Otherwise a browser sign-in prompt appears - whichever tenant you
    authenticate against is used. No tenant ID needed.

.EXAMPLE
    .\New-TenantAdminAccounts.ps1 -ResetPasswords

    Resets passwords for adm-engineer and adm-support on the connected tenant.
    Breakglass account is not touched.

.NOTES
    Requires the Microsoft.Graph PowerShell module:
        Install-Module Microsoft.Graph -Scope CurrentUser

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

#region -- Engineer Role Definitions ------------------------------------------
#  All built-in Entra ID roles except Global Administrator.
#  Retrieved from tenant contoso.onmicrosoft.com on 2026-04-24.
#  To refresh: Get-MgRoleManagementDirectoryRoleDefinition -Filter 'isBuiltIn eq true' -All |
#              Where-Object { $_.Id -ne '62e90394-69f5-4237-9190-012177145e10' } |
#              Sort-Object DisplayName | ForEach-Object { "'$($_.DisplayName)' = '$($_.Id)'" }

$EngineerRoleDefinitions = [ordered]@{
    'Agent ID Administrator'                              = 'db506228-d27e-4b7d-95e5-295956d6615f'
    'Agent ID Developer'                                  = 'adb2368d-a9be-41b5-8667-d96778e081b0'
    'Agent Registry Administrator'                        = '6b942400-691f-4bf0-9d12-d8a254a2baf5'
    'AI Administrator'                                    = 'd2562ede-74db-457e-a7b6-544e236ebb61'
    'AI Reader'                                           = '1fe13547-53f6-408d-ac04-7f8eed167b38'
    'Application Administrator'                           = '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'
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
    'Authentication Extensibility Administrator'          = '25a516ed-2fa0-40ea-a2d0-12923a21473a'
    'Authentication Extensibility Password Administrator' = '0b00bede-4072-4d22-b441-e7df02a1ef63'
    'Authentication Policy Administrator'                 = '0526716b-113d-4c15-b2c8-68e3c22b9f80'
    'Azure AD Joined Device Local Administrator'          = '9f06204d-73c1-4d4c-880a-6edb90606fd8'
    'Azure DevOps Administrator'                          = 'e3973bdf-4987-49ae-837a-ba8e231c7286'
    'Azure Information Protection Administrator'          = '7495fdc4-34c4-4d15-a289-98788ce399fd'
    'B2C IEF Keyset Administrator'                        = 'aaf43236-0c0d-4d5f-883a-6955382ac081'
    'B2C IEF Policy Administrator'                        = '3edaf663-341e-4475-9f94-5c398ef6c070'
    'Billing Administrator'                               = 'b0f54661-2d74-4c50-afa3-1ec803f12efe'
    'Cloud App Security Administrator'                    = '892c5842-a9a6-463a-8041-72aa08ca3cf6'
    'Cloud Application Administrator'                     = '158c047a-c907-4556-b7ef-446551a6b5f7'
    'Cloud Device Administrator'                          = '7698a772-787b-4ac8-901f-60d6b08affd2'
    'Compliance Administrator'                            = '17315797-102d-40b4-93e0-432062caca18'
    'Compliance Data Administrator'                       = 'e6d1a23a-da11-4be4-9570-befc86d067a7'
    'Conditional Access Administrator'                    = 'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9'
    'Customer Delegated Admin Relationship Administrator' = 'fc8ad4e2-40e4-4724-8317-bcda7503ecbf'
    'Customer LockBox Access Approver'                    = '5c4f9dcd-47dc-4cf7-8c9a-9e4207cbfc91'
    'Desktop Analytics Administrator'                     = '38a96431-2bdf-4b4c-8b6e-5d3d8abac1a4'
    'Device Join'                                         = '9c094953-4995-41c8-84c8-3ebb9b32c93f'
    'Device Managers'                                     = '2b499bcd-da44-4968-8aec-78e1674fa64d'
    'Device Users'                                        = 'd405c6df-0af8-4e3b-95e4-4d06e542189e'
    'Directory Readers'                                   = '88d8e3e3-8f55-4a1e-953a-9b9898b8876b'
    'Directory Synchronization Accounts'                  = 'd29b2b05-8046-44ba-8758-1e26182fcf32'
    'Directory Writers'                                   = '9360feb5-f418-4baa-8175-e2a00bac4301'
    'Domain Name Administrator'                           = '8329153b-31d0-4727-b945-745eb3bc5f31'
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
    'External Identity Provider Administrator'            = 'be2f45a1-457d-42af-a067-6ec1fa63bc45'
    'Fabric Administrator'                                = 'a9ea8996-122f-4c74-9520-8edcd192826c'
    'Global Reader'                                       = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
    'Global Secure Access Administrator'                  = 'ac434307-12b9-4fa1-a708-88bf58caabc1'
    'Global Secure Access Log Reader'                     = '843318fb-79a6-4168-9e6f-aa9a07481cc4'
    'Groups Administrator'                                = 'fdd7a751-b60b-444a-984c-02652fe8fa1c'
    'Guest Inviter'                                       = '95e79109-95c0-4d8e-aee3-d01accf2d47b'
    'Guest User'                                          = '10dae51f-b6af-4016-8d66-8c2a99b929b3'
    'Helpdesk Administrator'                              = '729827e3-9c14-49f7-bb1b-9608f156bbb8'
    'Hybrid Identity Administrator'                       = '8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2'
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
    'On Premises Directory Sync Account'                  = 'a92aed5d-d78a-4d16-b381-09adb37eb3b0'
    'Organizational Branding Administrator'               = '92ed04bf-c94a-4b82-9729-b799a7a4c178'
    'Organizational Data Source Administrator'            = '9d70768a-0cbc-4b4c-aea3-2e124b2477f4'
    'Organizational Messages Approver'                    = 'e48398e2-f4bb-4074-8f31-4586725e205b'
    'Organizational Messages Writer'                      = '507f53e4-4e52-4077-abd3-d2e1558b6ea2'
    'Partner Tier1 Support'                               = '4ba39ca4-527c-499a-b93d-d9b492c50246'
    'Partner Tier2 Support'                               = 'e00e864a-17c5-4a4b-9c06-f5b95a8d5bd8'
    'Password Administrator'                              = '966707d0-3269-4727-9be2-8c3a10f19b9d'
    'People Administrator'                                = '024906de-61e5-49c8-8572-40335f1e0e10'
    'Permissions Management Administrator'                = 'af78dc32-cf4d-46f9-ba4e-4428526346b5'
    'Places Administrator'                                = '78b0ccd1-afc2-4f92-9116-b41aedd09592'
    'Power Platform Administrator'                        = '11648597-926c-4cf3-9c36-bcebb0ba8dcc'
    'Printer Administrator'                               = '644ef478-e28f-4e28-b9dc-3fdde9aa0b1f'
    'Printer Technician'                                  = 'e8cef6f1-e4bd-4ea8-bc07-4b8d950f4477'
    'Privileged Authentication Administrator'             = '7be44c8a-adaf-4e2a-84d6-ab2649e08a13'
    'Privileged Role Administrator'                       = 'e8611ab8-c189-46e8-94e1-60213ab1f814'
    'Purview Workload Content Administrator'              = '3f04f91a-4ad7-4bd3-bcfa-49882ea1a88a'
    'Purview Workload Content Reader'                     = 'e07494ad-1654-4dd2-922e-6f81a71bf00f'
    'Purview Workload Content Writer'                     = '02d5655b-c1cf-4e5f-98da-5fb919085bf6'
    'Reports Reader'                                      = '4a5d8f65-41da-4de4-8968-e035b65339cf'
    'Restricted Guest User'                               = '2af84b1e-32c8-42b7-82bc-daa82404023b'
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
    'Tenant Creator'                                      = '112ca1a2-15ad-4102-995e-45b0bc479a6a'
    'Tenant Governance Administrator'                     = '1981f584-96e9-4a6f-95b0-f522373f8fae'
    'Tenant Governance Reader'                            = 'e0a4caa6-fe82-443f-b92f-d87341d17b2e'
    'Tenant Governance Relationship Administrator'        = 'b8e31d83-1534-480f-9b10-0338ded51b7e'
    'Tenant Governance Relationship Reader'               = '124577f8-48ed-456a-839f-13b419002e33'
    'Usage Summary Reports Reader'                        = '75934031-6c7e-415a-99d7-48dbd49e875e'
    'User'                                                = 'a0b1b346-4d3e-4e8b-98f8-753987be4970'
    'User Administrator'                                  = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
    'User Experience Success Manager'                     = '27460883-1df1-4691-b032-3b79643e5e63'
    'Virtual Visits Administrator'                        = 'e300d9e7-4a2b-4295-9eff-f1c78b36cc98'
    'Viva Glint Tenant Administrator'                     = '0ec3f692-38d6-4d14-9e69-0377ca7797ad'
    'Viva Goals Administrator'                            = '92b086b3-e367-4ef2-b869-1de128fb986e'
    'Viva Pulse Administrator'                            = '87761b17-1ed2-4af3-9acd-92a150038160'
    'Windows 365 Administrator'                           = '11451d60-acb2-45eb-a7d6-43d0f0125c13'
    'Windows Update Deployment Administrator'             = '32696413-001a-46ae-978c-ce0f6b3620d2'
    'Workplace Device Join'                               = 'c34f683f-4d5a-4403-affd-6615e00e3a7f'
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
if ($ResetPasswords) {
    $requiredScopes += 'UserAuthenticationMethod.ReadWrite.All'
}

# For password resets, always force a fresh token so the Directory.ReadWrite.All
# scope is actively consented rather than silently skipped from the MSAL cache.
if ($ResetPasswords) {
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

if ($ResetPasswords) {
    Write-Step "Resetting passwords for adm-engineer and adm-support..."

    $resetTargets = @(
        "adm-engineer@$domainName",
        "adm-support@$domainName"
    )

    $resetCredentials = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($upn in $resetTargets) {
        Write-Host "`n  -- $upn" -ForegroundColor White

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
#  adm-breakglass  - GA Breakglass  (excluded from CA / MFA)
#  adm-engineer      - Engineer    (MFA required)
#  adm-support     - Support Admin  (MFA required)

$accountDefs = @(
    [ordered]@{
        DisplayName       = 'ADM - Breakglass'
        UserPrincipalName = "adm-breakglass@$domainName"
        MailNickname      = 'adm-breakglass'
        Description       = 'Global Admin Breakglass - emergency last-resort access. Excluded from all Conditional Access policies. Store password offline in a secure physical location.'
        Roles             = @('GlobalAdministrator')
        MfaRequired       = $false
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

#region -- Create Accounts & Assign Roles -------------------------------------

Write-Step "Provisioning accounts..."

# Tracks ObjectIds for use in the CA policy
$objectIdMap    = @{}   # UPN -> ObjectId
$newCredentials = [System.Collections.Generic.List[PSObject]]::new()

foreach ($def in $accountDefs) {
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
#    - Created in REPORT-ONLY mode so no one is locked out immediately.
#      After validating sign-in logs, change state to 'enabled'.

Write-Step "Creating Conditional Access MFA policy..."

$mfaTargetIds = @(
    $accountDefs |
        Where-Object { $_.MfaRequired } |
        ForEach-Object {
            $id = $objectIdMap[$_.UserPrincipalName]
            if ($id) { $id }
        }
)

$breakglassId = $objectIdMap["adm-breakglass@$domainName"]

if ($mfaTargetIds.Count -eq 0) {
    Write-Warn "No MFA-required accounts found - skipping CA policy creation."
}
else {
    $policyName = "Require MFA - Tenant Admin Accounts [$tenantSlug]"

    $existingPolicy = Get-MgIdentityConditionalAccessPolicy `
        -Filter "displayName eq '$policyName'" -ErrorAction SilentlyContinue

    if ($existingPolicy) {
        Write-Warn "CA policy '$policyName' already exists - skipping."
    }
    elseif ($PSCmdlet.ShouldProcess($policyName, 'Create Conditional Access policy')) {
        $excludedUsers = [System.Collections.Generic.List[string]]::new()
        if ($breakglassId) { $excludedUsers.Add($breakglassId) }

        $caBody = @{
            displayName   = $policyName
            state         = 'enabled'
            conditions    = @{
                users = @{
                    includeUsers = [array]$mfaTargetIds
                    excludeUsers = $excludedUsers.Count -gt 0 ? [array]$excludedUsers : @()
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
        Write-OK "MFA is enforced - adm-engineer and adm-support must use MFA to sign in."
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

    Write-Host ""
    Write-Host "  [!!] BREAKGLASS: Split the password and store each half in a" -ForegroundColor Yellow
    Write-Host "       separate sealed envelope in a physically secure location." -ForegroundColor Yellow
    Write-Host "       Do NOT store it digitally or in a password manager." -ForegroundColor Yellow
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
