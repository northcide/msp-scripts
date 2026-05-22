#Requires -Version 7.1
<#
.SYNOPSIS
    Update notification email addresses on breakglass Purview alert policies.

.DESCRIPTION
    Opens a browser sign-in window, connects to the authenticated tenant's
    Security & Compliance Center, and updates the notification recipients
    on breakglass-related Purview protection alert policies (typically
    created manually in the Purview portal as part of tenant hardening,
    after the accounts themselves are provisioned).

    Policies matched by name pattern:
      • "Breakglass Sign-In - <upn>"            (one per breakglass account)
      • "CA Policy Add/Update/Delete [<tenant>]"

    Requires an E5 or E3 + Threat Intelligence subscription — these policies
    can only exist if they were created by the provisioning script on a
    qualifying tenant.

.PARAMETER NewEmails
    One or more email addresses to set as the new notification recipients.
    Separate multiple addresses with spaces or commas.
    If omitted, the script will prompt interactively via TUI.

.EXAMPLE
    .\Update-BreakglassAlertEmail.ps1

.EXAMPLE
    .\Update-BreakglassAlertEmail.ps1 -NewEmails alerts@example.com

.NOTES
    Requires ExchangeOnlineManagement module (installed automatically if missing).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]] $NewEmails = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Default email recipients ──────────────────────────────────────────────────
#  Edit this to change the pre-filled default in the menu.
$DefaultAlertEmails = @('alerts@example.com')

#region -- Output Helpers -------------------------------------------------------

function Write-Step { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "   [OK]  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "   [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "   [XX]  $Msg" -ForegroundColor Red }

#endregion

#region -- Interactive Setup Menu -----------------------------------------------
#
#  Two fields only: notification emails (text) + WhatIf (checkbox).
#  Navigation: ↑↓ navigate   space/enter activate text field or toggle checkbox
#              enter anywhere (outside edit mode) = run   esc = cancel

function Show-UpdateMenuFallback {
    [OutputType([hashtable])]
    param()

    Write-Host ""
    Write-Host "  UPDATE-BREAKGLASSALERTEMAIL" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  A browser sign-in window will open after you press Enter." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  NEW NOTIFICATION EMAILS  (space or comma separated)" -ForegroundColor DarkGray
    Write-Host "  Default: $($DefaultAlertEmails -join ' ')" -ForegroundColor DarkGray
    $raw = (Read-Host "  Emails (Enter to keep default)").Trim()
    $em  = if ([string]::IsNullOrWhiteSpace($raw)) {
        $DefaultAlertEmails
    } else {
        @($raw -split '[,\s]+' | Where-Object { $_ -ne '' })
    }

    Write-Host ""
    $wi = (Read-Host "  WhatIf - dry run, no changes? [y/N]") -match '^[yY]'
    Write-Host ""

    return @{ Emails = [string[]]$em; WhatIf = $wi }
}

function Show-UpdateMenu {
    [OutputType([hashtable])]
    param()

    $rawOk = $false
    try { $rawOk = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsInputRedirected } catch {}
    if (-not $rawOk) { return Show-UpdateMenuFallback }

    $ESC = [char]27

    # ── Mutable state ─────────────────────────────────────────────────────────
    $emails  = if ($script:NewEmails -and $script:NewEmails.Count -gt 0) {
                   $script:NewEmails -join ' '
               } else {
                   $DefaultAlertEmails -join ' '
               }
    $whatIf  = $false
    $focus   = 0       # 0 = Emails   1 = WhatIf
    $editing = $false
    $done    = $false
    $cancel  = $false
    $lineCount = 0
    $isFirst   = $true

    # ── Render helpers ────────────────────────────────────────────────────────
    $fp = {
        param([int]$idx)
        if ($focus -eq $idx) { return "$ESC[97m > $ESC[0m" }
        return '   '
    }
    $cb = {
        param([bool]$on)
        if ($on) { return "$ESC[92m[x]$ESC[0m" }
        return "[ ]"
    }
    $fc = {
        param([int]$idx)
        if ($focus -eq $idx) { return "$ESC[97m" }
        return "$ESC[37m"
    }
    $tf = {
        param([string]$val, [int]$idx)
        $cur    = if ($editing -and $focus -eq $idx) { "$ESC[97m|$ESC[0m" } else { '' }
        $colour = if ($val) { "$ESC[33m" } else { "$ESC[90m" }
        $shown  = if ($val) { $val } else { '(press space to edit)' }
        return "$colour$shown$ESC[0m$cur"
    }

    # ── Render + key loop ─────────────────────────────────────────────────────
    [Console]::Write("$ESC[?25l")

    try {
        while ($true) {

            $lines = [System.Collections.Generic.List[string]]::new()

            $lines.Add("")
            $lines.Add("  $ESC[96;1mUPDATE-BREAKGLASSALERTEMAIL$ESC[0m")
            $lines.Add("  $ESC[90m────────────────────────────────────────────────────────$ESC[0m")
            $lines.Add("")
            $lines.Add("  $ESC[90mA browser sign-in window will open when you press Enter.$ESC[0m")
            $lines.Add("")

            # NOTIFICATION EMAILS
            $lines.Add("  $ESC[90mNEW NOTIFICATION EMAILS  $ESC[2m(space-separated · replaces current recipients)$ESC[0m")
            $lines.Add("$(& $fp 0)$ESC[90m>$ESC[0m  $(& $tf $emails 0)")
            $lines.Add("")

            # OPTIONS
            $lines.Add("  $ESC[90mOPTIONS$ESC[0m")
            $lines.Add("$(& $fp 1)$(& $cb $whatIf)  $(& $fc 1)WhatIf  $ESC[90m$ESC[2m(dry run -- no changes made)$ESC[0m")
            $lines.Add("")

            # FOOTER
            $lines.Add("  $ESC[90m────────────────────────────────────────────────────────$ESC[0m")
            if ($editing) {
                $lines.Add("  $ESC[93mtyping -- space between addresses -- enter or esc to finish$ESC[0m")
            } else {
                $lines.Add("  $ESC[90m  up/down navigate   space edit/toggle   enter run   esc cancel$ESC[0m")
            }
            $lines.Add("")

            if (-not $isFirst) { [Console]::Write("$ESC[$($lineCount)A") }
            foreach ($ln in $lines) { [Console]::WriteLine("$ESC[2K$ln") }
            $lineCount = $lines.Count
            $isFirst   = $false

            if ($done -or $cancel) { break }

            $key = $null
            try { $key = [Console]::ReadKey($true) } catch { $cancel = $true; continue }

            if ($editing) {
                switch ($key.Key) {
                    ([ConsoleKey]::Enter)     { $editing = $false }
                    ([ConsoleKey]::Escape)    { $editing = $false }
                    ([ConsoleKey]::Tab)       { $editing = $false }
                    ([ConsoleKey]::Backspace) {
                        if ($emails.Length -gt 0) { $emails = $emails.Substring(0, $emails.Length - 1) }
                    }
                    default {
                        $ch = $key.KeyChar
                        if ([int]$ch -ge 32 -and [int]$ch -le 126) { $emails += [string]$ch }
                    }
                }
            } else {
                $navItems = @(0, 1)
                $pos      = [Array]::IndexOf($navItems, $focus)

                switch ($key.Key) {
                    ([ConsoleKey]::UpArrow)   { $pos = [Math]::Max(0, $pos - 1); $focus = $navItems[$pos] }
                    ([ConsoleKey]::DownArrow) { $pos = [Math]::Min($navItems.Length - 1, $pos + 1); $focus = $navItems[$pos] }
                    ([ConsoleKey]::Spacebar) {
                        switch ($focus) {
                            0 { $editing = $true }
                            1 { $whatIf  = -not $whatIf }
                        }
                    }
                    ([ConsoleKey]::Enter) {
                        if ($focus -eq 0) { $editing = $true } else { $done = $true }
                    }
                    ([ConsoleKey]::Escape) { $cancel = $true }
                }
            }
        }
    } finally {
        [Console]::Write("$ESC[?25h")
    }

    if ($cancel) { return $null }

    return @{
        Emails = [string[]]($emails -split '[,\s]+' | Where-Object { $_ -ne '' })
        WhatIf = $whatIf
    }
}

#endregion

#region -- Prerequisites --------------------------------------------------------

Write-Step "Checking prerequisites..."

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Warn "ExchangeOnlineManagement not found — installing..."
    try {
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
        Write-OK "Module installed."
    } catch {
        Write-Fail "Failed to install ExchangeOnlineManagement: $_"
        exit 1
    }
} else {
    Write-OK "ExchangeOnlineManagement is available."
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

#endregion

#region -- Interactive menu (or use params) -------------------------------------

if ($NewEmails.Count -eq 0) {
    Clear-Host
    $opts = Show-UpdateMenu
    if ($null -eq $opts) {
        Write-Host "`n  Cancelled." -ForegroundColor DarkGray
        exit 0
    }
    $NewEmails = $opts.Emails
    if ($opts.WhatIf) { $WhatIfPreference = [System.Management.Automation.ActionPreference]::Continue }
}

if (-not $NewEmails -or $NewEmails.Count -eq 0) { $NewEmails = $DefaultAlertEmails }

# Validate email format
$invalid = @($NewEmails | Where-Object { $_ -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$' })
if ($invalid.Count -gt 0) {
    Write-Fail "Invalid email address(es): $($invalid -join ', ')"
    exit 1
}

#endregion

#region -- Connect --------------------------------------------------------------

Write-Step "Connecting to Security & Compliance Center..."
Write-Host "   A browser sign-in window will open." -ForegroundColor DarkGray

$connected = $false
try {
    Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop
    $connected = $true

    # Discover which tenant we landed in
    $orgName = try {
        (Get-OrganizationConfig -ErrorAction Stop).Name
    } catch { '(unknown)' }

    Write-OK "Connected to: $orgName"
} catch {
    Write-Fail "Connection failed: $_"
    Write-Host ""
    Write-Host "   Troubleshooting tips:" -ForegroundColor DarkGray
    Write-Host "   · Sign in with a Global Admin or Compliance Admin account." -ForegroundColor DarkGray
    Write-Host "   · Ensure the account has access to the Security & Compliance Center." -ForegroundColor DarkGray
    exit 1
}

#endregion

try {

    #region -- Find matching alert policies -------------------------------------

    Write-Step "Scanning for breakglass alert policies..."

    $allAlerts = @(Get-ProtectionAlert -ErrorAction Stop)
    Write-OK "$($allAlerts.Count) total protection alert policies found."

    $matchingAlerts = @($allAlerts | Where-Object {
        $_.Name -match '^Breakglass Sign-In - ' -or
        $_.Name -match '^CA Policy (Add|Update|Delete) \['
    })

    if ($matchingAlerts.Count -eq 0) {
        Write-Warn "No breakglass alert policies found in this tenant."
        Write-Host ""
        Write-Host "   Expected names matching:" -ForegroundColor DarkGray
        Write-Host "     · Breakglass Sign-In - <username>  (e.g. Breakglass Sign-In - adm-breakglass-msp)" -ForegroundColor DarkGray
        Write-Host "     · CA Policy Add/Update/Delete [<tenant>]" -ForegroundColor DarkGray
        Write-Host ""

        # Fuzzy search: anything with "breakglass" or "CA Policy" in the name (case-insensitive)
        $fuzzy = @($allAlerts | Where-Object {
            $_.Name -match '(?i)breakglass' -or $_.Name -match '(?i)^CA Policy '
        } | Sort-Object Name)

        if ($fuzzy.Count -gt 0) {
            Write-Host "   Possible near-matches found (naming may differ from expected):" -ForegroundColor DarkGray
            $fuzzy | ForEach-Object { Write-Host "     · $($_.Name)" -ForegroundColor Yellow }
            Write-Host ""
            Write-Host "   If these are the right policies, the naming pattern has changed." -ForegroundColor DarkGray
            Write-Host "   Let the script author know the exact names shown above." -ForegroundColor DarkGray
        } else {
            Write-Host "   Fuzzy search (breakglass / CA Policy) also found nothing." -ForegroundColor DarkGray
            Write-Host "   All $($allAlerts.Count) policies present:" -ForegroundColor DarkGray
            $allAlerts | Sort-Object Name | ForEach-Object { Write-Host "     · $($_.Name)" -ForegroundColor DarkGray }
        }
        Write-Host ""
        exit 0
    }

    Write-OK "$($matchingAlerts.Count) breakglass alert $(if ($matchingAlerts.Count -eq 1) { 'policy' } else { 'policies' }) found:"
    Write-Host ""
    foreach ($alert in $matchingAlerts) {
        $cur = if ($alert.NotifyUser) { $alert.NotifyUser -join ', ' } else { '(none)' }
        Write-Host "   $($alert.Name)" -ForegroundColor White
        Write-Host "     Current recipients: $cur" -ForegroundColor DarkGray
    }

    #endregion

    #region -- Confirm + apply --------------------------------------------------

    Write-Host ""
    Write-Host "   New recipients will be:" -ForegroundColor DarkGray
    $NewEmails | ForEach-Object { Write-Host "     · $_" -ForegroundColor Cyan }
    Write-Host ""

    if ($WhatIfPreference -ne [System.Management.Automation.ActionPreference]::Continue) {
        $confirm = (Read-Host "   Apply to all $($matchingAlerts.Count) $(if ($matchingAlerts.Count -eq 1) { 'policy' } else { 'policies' })? [Y/N]").Trim()
        if ($confirm -notmatch '^[Yy]') {
            Write-Host ""
            Write-Warn "Cancelled — no changes made."
            exit 0
        }
    }

    Write-Step "Updating policies..."

    $successCount = 0
    $failCount    = 0

    foreach ($alert in $matchingAlerts) {
        if ($PSCmdlet.ShouldProcess($alert.Name, "Set-ProtectionAlert NotifyUser")) {
            try {
                Set-ProtectionAlert `
                    -Identity   $alert.Name `
                    -NotifyUser ([string[]]$NewEmails) `
                    -ErrorAction Stop
                Write-OK "$($alert.Name)"
                $successCount++
            } catch {
                Write-Fail "$($alert.Name): $_"
                $failCount++
            }
        } else {
            Write-Host "   [WhatIf] Would update: $($alert.Name)" -ForegroundColor DarkGray
        }
    }

    #endregion

    #region -- Summary ----------------------------------------------------------

    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray

    if ($WhatIfPreference -eq [System.Management.Automation.ActionPreference]::Continue) {
        Write-Host "  WhatIf run complete — no changes made." -ForegroundColor Yellow
    } elseif ($failCount -eq 0) {
        Write-Host "  $successCount $(if ($successCount -eq 1) { 'policy' } else { 'policies' }) updated successfully." -ForegroundColor Green
        Write-Host "  Alerts will now notify:" -ForegroundColor DarkGray
        $NewEmails | ForEach-Object { Write-Host "    · $_" -ForegroundColor Cyan }
    } else {
        Write-Host "  $successCount updated  |  $failCount failed — review errors above." -ForegroundColor Yellow
    }
    Write-Host ""

    #endregion

} finally {
    if ($connected) {
        Write-Step "Disconnecting..."
        try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue; Write-OK "Disconnected." } catch {}
    }
    Write-Host ""
}
