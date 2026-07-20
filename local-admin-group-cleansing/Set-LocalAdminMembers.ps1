<#
.SYNOPSIS
    Enforces a known, minimal membership of the local Administrators group on
    Windows 10/11 workstations and guarantees a managed break-glass local admin.

.DESCRIPTION
    Designed to be deployed from NinjaRMM (run as SYSTEM) against Windows 10/11
    workstations. After it runs, the local Administrators group contains only:

        * Domain Admins of the AD domain the machine is joined to
          (only when the machine is domain-joined).
        * The managed local account named in the NinjaRMM Documentation
          attribute 'LocalAdminUsername', using the password in the
          'LocalAdminPassword' attribute of the same document (read per
          organization via Ninja-Property-Docs-Get). The account is created if
          missing; if present it is enabled and its password is reset to the
          documented value.

    The following are PRESERVED by design and never removed:
        * The built-in Administrator account (well-known SID ending in -500).
          It is left exactly as found (not enabled, not modified).
        * Microsoft Entra (Azure AD) admin principals (SIDs beginning S-1-12-1-),
          so Global Administrators / Azure AD Joined Device Local Administrators
          are not locked out on Entra- or Hybrid-joined devices.

    Everything else (stray local users, other domain users/groups, legacy MSP
    accounts, orphaned/unresolvable SIDs) is removed from the group.

    The managed account's password is set to never expire because it is rotated
    centrally via NinjaRMM.

    SAFETY: if the username or password cannot be obtained the script aborts
    BEFORE making any change, so a machine can never be stripped of admins
    without a guaranteed replacement.

.PARAMETER LocalAdminUsername
    Override for the managed account name. When omitted, the value is read from
    the 'LocalAdminUsername' attribute of the NinjaRMM Documentation document.
    Intended for local testing.

.PARAMETER LocalAdminPassword
    Override for the managed account password (plain text). When omitted, the
    value is read from the 'LocalAdminPassword' attribute of the NinjaRMM
    Documentation document. Intended for local testing.

.PARAMETER DocTemplate
    NinjaRMM Documentation template name that holds the managed credentials.
    Defaults to 'LocalAdminAccount' (a single-page documentation item, where the
    template name and document name are the same). Override only if yours differs.

.PARAMETER DocName
    Document name within DocTemplate (used by the 3-arg read form). Defaults to
    'LocalAdminAccount'. Override only if your document differs.

.PARAMETER UsernameFields
.PARAMETER PasswordFields
    Candidate field identifiers to read for the username / password, tried in
    order. NinjaOne field identifiers are camelCase (e.g. 'localAdminUsername');
    the label-cased name is tried as a fallback.

.PARAMETER DryRun
    Report-only. Shows every account/group change that WOULD be made without
    making any change.

.PARAMETER WhatIf
    Standard ShouldProcess preview. Equivalent in effect to -DryRun.

.EXAMPLE
    .\Set-LocalAdminMembers.ps1

    Normal NinjaRMM run. Reads LocalAdminUsername / LocalAdminPassword from the
    device's custom fields and enforces the group membership.

.EXAMPLE
    .\Set-LocalAdminMembers.ps1 -DryRun -LocalAdminUsername svc-admin -LocalAdminPassword 'P@ssw0rd!'

    Previews the changes on a test machine without touching anything.

.NOTES
    Minimum OS Architecture Supported: Windows 10 / Windows 11 (workstation).
    Refuses to run on Server SKUs.

    Runs under Windows PowerShell 5.1 (stock on Windows 10/11). Does not require
    PowerShell 7 or RSAT.

    Must run elevated (SYSTEM when deployed via NinjaRMM).

    NinjaRMM Documentation required (single-page item 'LocalAdminAccount' by
    default), readable by the technician/role the automation runs as:
        localAdminUsername  - Text
        localAdminPassword  - Text  (must NOT be a secure/encrypted attribute;
                                     secure documentation fields are write-only
                                     and cannot be read back by the CLI)
        ignoreLocalGroups   - Text  (OPTIONAL; comma-delimited list of principals
                                     - users OR groups, local OR domain - to keep
                                     if already in Administrators. e.g.
                                     "HKKXEON\Helpdesk, support")

    Exit codes: 0 = success, 1 = failure / aborted.
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$LocalAdminUsername,
    [string]$LocalAdminPassword,

    # NinjaRMM Documentation location of the managed credentials (resolved for
    # the device's organization). 'LocalAdminAccount' is a single-page item, so
    # it is BOTH the template name (for the -Single read form) and the document
    # name (for the 3-arg read form); the resolver tries both. Override only if
    # your documentation is named differently.
    [string]$DocTemplate = 'LocalAdminAccount',
    [string]$DocName     = 'LocalAdminAccount',

    # Candidate field identifiers, tried in order. NinjaOne field identifiers
    # are camelCase (e.g. vpnSharedSecret), but the label casing is tried too.
    [string[]]$UsernameFields = @('localAdminUsername', 'LocalAdminUsername'),
    [string[]]$PasswordFields = @('localAdminPassword', 'LocalAdminPassword'),

    # Optional comma-delimited list of principals to PRESERVE if already in the
    # Administrators group (never removed; never added). Matched by SID and by
    # name (a bare name matches the member's leaf; a DOMAIN\name must match in
    # full). Read from these candidate field identifiers, in order.
    #
    # NOTE: if a field that clearly exists returns "Unable to find the specified
    # field", it is almost always a PERMISSIONS problem - the role the automation
    # runs as needs read access to that Documentation Custom Field. The CLI
    # reports a missing read permission as a not-found error, not access-denied.
    [string[]]$IgnoreGroupsFields = @('ignoreLocalGroups', 'ignorelocalgroups'),

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region -- Output Helpers -----------------------------------------------------

function Write-Step { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "   [OK]  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "   [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "   [XX]  $Msg" -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host "   [..]  $Msg" -ForegroundColor Gray }

# Treat -WhatIf and -DryRun identically: both mean "make no changes".
$Preview = $DryRun.IsPresent -or ($WhatIfPreference -eq $true)

# Well-known SID of the local Administrators group (language-independent).
$AdminsGroupSid = 'S-1-5-32-544'

#endregion

#region -- NinjaRMM field access ----------------------------------------------

function Get-NinjaDocValue {
    <#
        Resolves a single Documentation value for the device's organization,
        tolerant of how the item is laid out and how its field is named.

        NinjaOne exposes documentation reads two ways:
            * Ninja-Property-Docs-Get-Single "<template>" "<field>"
              for single-page items (template name only).
            * Ninja-Property-Docs-Get "<template>" "<document>" <field>
              for a named document inside a multi-document template.
        It also distinguishes a field's camelCase *identifier* from its display
        *label*. We don't know the exact shape for every tenant, so we probe the
        candidate forms/field-names in order and return the first non-empty hit.
        Returns $null if nothing resolves (helpers absent, or all probes empty).

        NOTE: Documentation *secure* (encrypted) attributes are WRITE-ONLY and
        cannot be read back. The password field must be plain Text.
    #>
    param(
        [Parameter(Mandatory)][string]$Template,
        [Parameter(Mandatory)][string]$Document,
        [Parameter(Mandatory)][string[]]$Fields
    )

    $haveSingle = [bool](Get-Command 'Ninja-Property-Docs-Get-Single' -ErrorAction SilentlyContinue)
    $haveGet    = [bool](Get-Command 'Ninja-Property-Docs-Get'        -ErrorAction SilentlyContinue)
    if (-not ($haveSingle -or $haveGet)) { return $null }

    foreach ($field in $Fields) {
        if ($haveSingle) {
            try {
                $v = & Ninja-Property-Docs-Get-Single $Template $field 2>$null
                if (Test-DocValue $v) { return ([string]$v).Trim() }
            } catch { }
        }
        if ($haveGet) {
            try {
                $v = & Ninja-Property-Docs-Get $Template $Document $field 2>$null
                if (Test-DocValue $v) { return ([string]$v).Trim() }
            } catch { }
        }
    }
    return $null
}

function Test-DocValue {
    # True only for a usable value. Rejects empty / "null" and the CLI's
    # not-found error text, which can surface on stdout and must never be
    # mistaken for a real field value.
    param($Value)
    $v = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $false }
    if ($v -eq 'null') { return $false }
    if ($v -match 'Unable to find the specified field') { return $false }
    return $true
}

#endregion

#region -- SID helpers --------------------------------------------------------

function ConvertTo-Sid {
    # Best-effort translation of an NTAccount string to a SID; $null on failure.
    param([Parameter(Mandatory)][string]$Account)
    try {
        return (New-Object System.Security.Principal.NTAccount($Account)).Translate(
            [System.Security.Principal.SecurityIdentifier]).Value
    } catch {
        return $null
    }
}

function Resolve-SidName {
    # Best-effort friendly name for a SID; returns "<unresolved>" if it can't.
    param([Parameter(Mandatory)][string]$Sid)
    try {
        return (New-Object System.Security.Principal.SecurityIdentifier($Sid)).Translate(
            [System.Security.Principal.NTAccount]).Value
    } catch {
        return '<unresolved>'
    }
}

function Test-IgnoredName {
    # True if a member's resolved name matches an ignore-list entry. A bare
    # entry (no domain/host prefix) matches the member's leaf name; an entry
    # that includes a prefix must match the full DOMAIN\name. Case-insensitive.
    param(
        [string]$Name,
        [System.Collections.Generic.List[string]]$List
    )
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -eq '<unresolved>') { return $false }
    if (-not $List -or $List.Count -eq 0) { return $false }
    $leaf = ($Name -split '\\')[-1]
    foreach ($n in $List) {
        if ($n -ieq $Name) { return $true }
        if ($n -notmatch '\\' -and $n -ieq $leaf) { return $true }
    }
    return $false
}

function Test-PrivilegedDomainGroup {
    # True if a SID is Domain Admins (-512) or Enterprise Admins (-519) of ANY
    # AD domain. Matched purely by SID pattern, so it needs no DC contact and
    # works regardless of whether domain-join detection succeeded - existing
    # privileged domain admins are therefore never stripped from a workstation
    # (e.g. when Get-DomainAdminsSid can't resolve them, or the box reads as
    # not-domain-joined). Adding the joined domain's Domain Admins when MISSING
    # still depends on Get-DomainAdminsSid; this only governs preservation.
    param([string]$Sid)
    return ($Sid -match '^S-1-5-21-\d+-\d+-\d+-(512|519)$')
}

function Get-DomainAdminsSid {
    <#
        Returns the Domain Admins SID for the joined domain, or $null if not
        domain-joined / not resolvable. Builds <domainSID>-512 from the machine's
        own domain computer account to stay language-independent, falling back to
        translating "<DOMAIN>\Domain Admins" by name.
    #>
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    if (-not $cs.PartOfDomain) { return $null }

    $netbios = $cs.Domain
    # The flat NetBIOS name is what NTAccount translation expects; Win32 reports
    # the DNS domain in .Domain on some configs, so trim to the first label.
    $flat = ($netbios -split '\.')[0]

    # Preferred: derive the domain SID from this computer's own account SID.
    $compSidStr = ConvertTo-Sid -Account ("{0}\{1}$" -f $flat, $env:COMPUTERNAME)
    if ($compSidStr) {
        try {
            $compSid   = New-Object System.Security.Principal.SecurityIdentifier($compSidStr)
            $domainSid = $compSid.AccountDomainSid
            if ($domainSid) {
                return (New-Object System.Security.Principal.SecurityIdentifier(
                    ("{0}-512" -f $domainSid.Value))).Value
            }
        } catch { }
    }

    # Fallback: resolve by (localized) group name.
    $byName = ConvertTo-Sid -Account ("{0}\Domain Admins" -f $flat)
    if ($byName) { return $byName }

    return $null
}

function Get-AdminsGroupMemberSids {
    <#
        Returns the SIDs (strings) of every member of the local Administrators
        group. Uses Get-LocalGroupMember first, then falls back to the ADSI
        WinNT provider when that cmdlet throws on orphaned/unresolvable SIDs
        (the well-known "Failed to compare two elements in the array" /
        principal-resolution failures).
    #>
    $sids = New-Object System.Collections.Generic.List[string]

    try {
        foreach ($m in Get-LocalGroupMember -SID $AdminsGroupSid -ErrorAction Stop) {
            if ($m.SID) { [void]$sids.Add($m.SID.Value) }
        }
        return $sids
    } catch {
        Write-Warn "Get-LocalGroupMember failed ($($_.Exception.Message)); using ADSI fallback."
    }

    # ADSI fallback - resolves the local group by SID, enumerates raw members,
    # and converts each member's objectSid byte array to a SID string.
    $groupName = (New-Object System.Security.Principal.SecurityIdentifier(
        $AdminsGroupSid)).Translate([System.Security.Principal.NTAccount]).Value
    $groupLeaf = ($groupName -split '\\')[-1]
    $group = [ADSI]("WinNT://./{0},group" -f $groupLeaf)

    foreach ($member in @($group.Invoke('Members'))) {
        try {
            $bytes = $member.GetType().InvokeMember(
                'objectSid', 'GetProperty', $null, $member, $null)
            $sid = (New-Object System.Security.Principal.SecurityIdentifier(
                [byte[]]$bytes, 0)).Value
            [void]$sids.Add($sid)
        } catch {
            Write-Warn "Could not read a member SID via ADSI: $($_.Exception.Message)"
        }
    }
    return $sids
}

function Remove-AdminMemberBySid {
    # Removes a SID from the Administrators group. Falls back to the ADSI WinNT
    # provider (which binds directly to a WinNT://<SID> path) for orphaned SIDs
    # that Remove-LocalGroupMember can't resolve.
    param([Parameter(Mandatory)][string]$Sid)

    try {
        Remove-LocalGroupMember -SID $AdminsGroupSid -Member $Sid -ErrorAction Stop
        return $true
    } catch {
        Write-Warn "Remove-LocalGroupMember failed for $Sid; trying ADSI."
    }

    try {
        $groupName = (New-Object System.Security.Principal.SecurityIdentifier(
            $AdminsGroupSid)).Translate([System.Security.Principal.NTAccount]).Value
        $groupLeaf = ($groupName -split '\\')[-1]
        $group = [ADSI]("WinNT://./{0},group" -f $groupLeaf)
        $group.Remove(("WinNT://{0}" -f $Sid))
        return $true
    } catch {
        Write-Fail "All removal methods failed for $Sid : $($_.Exception.Message)"
        return $false
    }
}

#endregion

$failed = $false
try {
    Write-Step "Local Administrators group cleansing"
    if ($Preview) { Write-Warn "PREVIEW MODE - no changes will be made." }

    # --- Guard: workstation only ---------------------------------------------
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    if ($os.ProductType -ne 1) {
        Write-Fail "This is not a workstation SKU (ProductType=$($os.ProductType)). Aborting."
        exit 1
    }
    Write-Info "OS: $($os.Caption)"

    # --- Step 1: obtain managed account credentials (with safety abort) ------
    Write-Step "Resolving managed local admin credentials"

    if ([string]::IsNullOrWhiteSpace($LocalAdminUsername)) {
        $LocalAdminUsername = Get-NinjaDocValue -Template $DocTemplate -Document $DocName -Fields $UsernameFields
    }
    if ([string]::IsNullOrWhiteSpace($LocalAdminPassword)) {
        $LocalAdminPassword = Get-NinjaDocValue -Template $DocTemplate -Document $DocName -Fields $PasswordFields
    }

    if ([string]::IsNullOrWhiteSpace($LocalAdminUsername) -or
        [string]::IsNullOrWhiteSpace($LocalAdminPassword)) {
        Write-Fail "LocalAdminUsername and/or LocalAdminPassword is empty. Aborting BEFORE any change to avoid lockout."
        exit 1
    }
    # Sanitize the username (strip any DOMAIN\ or host\ prefix; it's a local account).
    $LocalAdminUsername = ($LocalAdminUsername -split '\\')[-1]
    Write-OK "Managed account: $LocalAdminUsername"

    $securePassword = ConvertTo-SecureString $LocalAdminPassword -AsPlainText -Force

    # --- Step 2: ensure the managed account exists, enabled, pw reset --------
    Write-Step "Ensuring managed local account"

    $existing = Get-LocalUser -Name $LocalAdminUsername -ErrorAction SilentlyContinue

    if (-not $existing) {
        if ($Preview) {
            Write-Info "WOULD create local user '$LocalAdminUsername' (enabled, password never expires)."
        } else {
            New-LocalUser -Name $LocalAdminUsername `
                -Password $securePassword `
                -FullName $LocalAdminUsername `
                -Description 'Managed local admin - do not delete (NinjaRMM)' `
                -AccountNeverExpires `
                -PasswordNeverExpires `
                -ErrorAction Stop | Out-Null
            Write-OK "Created '$LocalAdminUsername'."
        }
    } else {
        if ($Preview) {
            Write-Info "WOULD enable '$LocalAdminUsername', reset its password, and set password-never-expires."
        } else {
            Enable-LocalUser -Name $LocalAdminUsername -ErrorAction Stop
            Set-LocalUser -Name $LocalAdminUsername `
                -Password $securePassword `
                -PasswordNeverExpires $true `
                -AccountNeverExpires `
                -ErrorAction Stop
            Write-OK "Enabled and reset password for '$LocalAdminUsername'."
        }
    }

    # Resolve the managed account SID (needed for the keep-list). In preview mode
    # the account may not exist yet, so this can be $null - handled below.
    $managedSid = $null
    $managedUser = Get-LocalUser -Name $LocalAdminUsername -ErrorAction SilentlyContinue
    if ($managedUser) {
        $managedSid = $managedUser.SID.Value
    } elseif (-not $Preview) {
        Write-Fail "Managed account '$LocalAdminUsername' could not be found after creation. Aborting."
        exit 1
    }

    # --- Step 3: build the keep-list -----------------------------------------
    Write-Step "Building authorized membership"

    $keep = New-Object System.Collections.Generic.HashSet[string] (
        [System.StringComparer]::OrdinalIgnoreCase)

    if ($managedSid) { [void]$keep.Add($managedSid) }

    $domainAdminsSid = Get-DomainAdminsSid
    if ($domainAdminsSid) {
        [void]$keep.Add($domainAdminsSid)
        Write-OK "Domain Admins SID resolved (will add if missing): $domainAdminsSid"
    } else {
        Write-Info "Domain Admins SID not resolved - won't be ADDED if missing. Any Domain/Enterprise Admins already present are still PRESERVED by SID."
    }

    # Optional ignore-list: principals to preserve if already present. Resolved
    # to SIDs where possible (robust against renames/localization); the raw
    # names are retained for name-based matching of anything that won't resolve.
    $ignoreNames = New-Object System.Collections.Generic.List[string]
    $ignoreSids  = New-Object System.Collections.Generic.HashSet[string] (
        [System.StringComparer]::OrdinalIgnoreCase)

    $ignoreRaw = Get-NinjaDocValue -Template $DocTemplate -Document $DocName -Fields $IgnoreGroupsFields
    if (-not [string]::IsNullOrWhiteSpace($ignoreRaw)) {
        foreach ($entry in ($ignoreRaw -split ',')) {
            $n = $entry.Trim()
            if ([string]::IsNullOrWhiteSpace($n)) { continue }
            [void]$ignoreNames.Add($n)
            $isid = ConvertTo-Sid -Account $n
            if ($isid) { [void]$ignoreSids.Add($isid) }
        }
    }
    if ($ignoreNames.Count -gt 0) {
        Write-OK ("Ignore-list (preserve if present): {0}" -f ($ignoreNames -join ', '))
    } else {
        Write-Info "No ignoreLocalGroups entries - nothing extra preserved."
    }

    # --- Step 4: enumerate current members -----------------------------------
    Write-Step "Reading current Administrators members"
    $currentSids = Get-AdminsGroupMemberSids
    Write-Info "Current member count: $($currentSids.Count)"

    # --- Step 5: reconcile ----------------------------------------------------
    Write-Step "Reconciling membership"

    # 5a. Add required principals that are missing.
    foreach ($req in @($managedSid, $domainAdminsSid)) {
        if (-not $req) { continue }
        if ($currentSids -notcontains $req) {
            $name = Resolve-SidName -Sid $req
            if ($Preview) {
                Write-Info "WOULD add $name ($req)."
            } else {
                Add-LocalGroupMember -SID $AdminsGroupSid -Member $req -ErrorAction Stop
                Write-OK "Added $name ($req)."
            }
        }
    }

    # 5b. Remove anything not authorized / not preserved.
    foreach ($sid in $currentSids) {
        $name = Resolve-SidName -Sid $sid
        $preserve = $false; $reason = ''
        if ($keep.Contains($sid))          { $preserve = $true; $reason = 'authorized' }
        elseif ($sid -like '*-500')        { $preserve = $true; $reason = 'built-in Administrator' }
        elseif ($sid -like 'S-1-12-1-*')   { $preserve = $true; $reason = 'Entra/Azure AD principal' }
        elseif (Test-PrivilegedDomainGroup -Sid $sid) { $preserve = $true; $reason = 'Domain/Enterprise Admins' }
        elseif ($ignoreSids.Contains($sid) -or (Test-IgnoredName -Name $name -List $ignoreNames)) {
            $preserve = $true; $reason = 'ignored (ignoreLocalGroups)'
        }

        if ($preserve) {
            Write-Info "Keep   $name ($sid) - $reason"
            continue
        }

        if ($Preview) {
            Write-Info "WOULD remove $name ($sid)."
        } else {
            if (Remove-AdminMemberBySid -Sid $sid) {
                Write-OK "Removed $name ($sid)."
            } else {
                $failed = $true
            }
        }
    }

    # --- Step 6: report resulting membership ---------------------------------
    # On a live run, re-read the group so the output reflects reality. In preview
    # the group is unchanged, so project the set the live run WOULD leave behind.
    Write-Step "Resulting Administrators membership"

    if ($Preview) {
        $projected = New-Object System.Collections.Generic.List[string]

        if ($managedSid) {
            Write-Info "WOULD contain: $(Resolve-SidName -Sid $managedSid) ($managedSid)"
            [void]$projected.Add($managedSid)
        } else {
            Write-Info "WOULD contain: $LocalAdminUsername (new account)"
            # No SID yet (account not created in preview); track by name so the
            # projected count includes it. This sentinel never matches a SID.
            [void]$projected.Add("(new) $LocalAdminUsername")
        }
        if ($domainAdminsSid -and $projected -notcontains $domainAdminsSid) {
            Write-Info "WOULD contain: $(Resolve-SidName -Sid $domainAdminsSid) ($domainAdminsSid)"
            [void]$projected.Add($domainAdminsSid)
        }
        foreach ($sid in $currentSids) {
            if ($projected -contains $sid) { continue }
            $nm = Resolve-SidName -Sid $sid
            $keepIt = $keep.Contains($sid) -or ($sid -like '*-500') -or ($sid -like 'S-1-12-1-*') -or
                      (Test-PrivilegedDomainGroup -Sid $sid) -or
                      $ignoreSids.Contains($sid) -or (Test-IgnoredName -Name $nm -List $ignoreNames)
            if ($keepIt) {
                Write-Info "WOULD contain: $nm ($sid)"
                [void]$projected.Add($sid)
            }
        }
        Write-Info "Projected member count: $($projected.Count)"
    } else {
        $finalSids = Get-AdminsGroupMemberSids
        foreach ($sid in $finalSids) {
            Write-OK "$(Resolve-SidName -Sid $sid) ($sid)"
        }
        Write-Info "Final member count: $($finalSids.Count)"
    }

    Write-Step "Done"
    if ($Preview) {
        Write-Warn "Preview complete - no changes were made."
    } elseif ($failed) {
        Write-Fail "Completed with one or more removal failures."
    } else {
        Write-OK "Local Administrators membership enforced."
    }
}
catch {
    Write-Fail "Unhandled error: $($_.Exception.Message)"
    Write-Fail $_.ScriptStackTrace
    exit 1
}

if ($failed) { exit 1 }
exit 0
