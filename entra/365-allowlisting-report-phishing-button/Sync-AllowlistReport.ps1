#Requires -Version 7.1
<#
.SYNOPSIS
    Apply a Defender for Office 365 allowlist + reporting posture to a new
    Microsoft 365 tenant for phishing-simulation onboarding (Ironscales).

.DESCRIPTION
    Reads the reference snapshot in .\reference\ and merges it into the
    signed-in target tenant. Merge semantics: adds missing entries, never
    removes. Re-runnable safely (idempotent).

    Touched settings:
      • Phishing Simulation advanced delivery   (PhishSimOverridePolicy / Rule)            — ExchangeOnlineManagement
      • PhishSim allowed simulation URLs        (TenantAllowBlockListItems)                — ExchangeOnlineManagement
      • Connection filter policy IP allow list  (HostedConnectionFilterPolicy)             — ExchangeOnlineManagement
      • Native Microsoft Report Phishing button (ReportSubmissionPolicy + Rule)            — ExchangeOnlineManagement       — gated on -InstallIronscales
      • Ironscales Report Phishing OWA add-in   (Centralized Deployment / IntegratedApps)  — O365CentralizedAddInDeployment — gated on -InstallIronscales

    Browser sign-in opens after the menu. Sign in as a Global Administrator
    on the target tenant.

.PARAMETER SignInAs
    Optional UPN to pre-fill in the browser sign-in. Use this to force a
    specific account when the cached token is for the wrong account or
    tenant.

.PARAMETER InstallIronscales
    Switch. When set, disables the native Microsoft Report Phishing button
    AND installs the Ironscales OWA add-in tenant-wide. When unset, both of
    those sections are SKIPPED. Also exposed as a checkbox in the TUI menu
    (default: checked).

.PARAMETER WhatIf
    Dry-run. No writes are made. Also exposed as a checkbox in the menu.

.EXAMPLE
    .\Sync-AllowlistReport.ps1
    Interactive TUI — toggle the Ironscales checkbox and WhatIf as needed.

.EXAMPLE
    .\Sync-AllowlistReport.ps1 -WhatIf
    Non-interactive dry-run preview.

.EXAMPLE
    .\Sync-AllowlistReport.ps1 -SignInAs adm-breakglass-msp@newclient.onmicrosoft.com
    Force sign-in as a specific Global Admin account.

.EXAMPLE
    .\Sync-AllowlistReport.ps1 -InstallIronscales:$false
    Run allowlist-only — don't touch the Report Phishing button or the
    Ironscales add-in.

.NOTES
    Requires:
      • ExchangeOnlineManagement module (auto-installed if missing).
      • O365CentralizedAddInDeployment module (auto-installed if missing) —
        only used when -InstallIronscales is set.

    Sign-in role needed: Global Administrator.
      • Settings 1–4 also work with a direct member of the Exchange
        "Organization Management" role group, but the Ironscales install
        (Centralized Deployment) strictly requires GA.

    Add-in install propagates to clients over 24–72h after deployment.

    To refresh the reference snapshot in .\reference\, edit the files by hand
    or use a one-off snippet — this script no longer has an Export mode.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $SignInAs,

    # Switch with explicit nullable backing so we can tell "not specified" from
    # "specified as $false." Default behavior (no parameter) leaves it to the
    # menu, which defaults to ON.
    [Nullable[bool]] $InstallIronscales
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Constants ─────────────────────────────────────────────────────────────────
$ReferenceDir            = Join-Path $PSScriptRoot 'reference'
$PhishSimDomainsFile     = Join-Path $ReferenceDir 'phishsim-domains.txt'
$PhishSimIpRangesFile    = Join-Path $ReferenceDir 'phishsim-ipranges.txt'
$PhishSimUrlsFile        = Join-Path $ReferenceDir 'phishsim-urls.txt'
$ConnFilterIpsFile       = Join-Path $ReferenceDir 'connection-filter-ipallowlist.txt'
$ReportSubmissionFile    = Join-Path $ReferenceDir 'report-submission-policy.json'
$IronscalesManifestFile  = Join-Path $ReferenceDir 'ironscales-owa-addin-manifest.xml'

$PhishSimPolicyName      = 'PhishSimOverridePolicy'
$ConnFilterPolicyName    = 'Default'
$ReportSubmissionPolicy  = 'DefaultReportSubmissionPolicy'

# Toggle fields written by Apply onto Set-ReportSubmissionPolicy.
$ReportSubmissionFields = @(
    'EnableReportToMicrosoft',
    'EnableThirdPartyAddress',
    'ThirdPartyReportAddresses',
    'ReportJunkToCustomizedAddress',
    'ReportJunkAddresses',
    'ReportNotJunkToCustomizedAddress',
    'ReportNotJunkAddresses',
    'ReportPhishToCustomizedAddress',
    'ReportPhishAddresses'
)

#region -- Output Helpers -------------------------------------------------------

function Write-Step { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "   [OK]  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "   [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "   [XX]  $Msg" -ForegroundColor Red }

# Tracks per-section outcome so the end-of-run summary can give a single,
# unambiguous verdict. Status is one of: OK, SKIPPED, FAILED.
$script:SectionResults = [System.Collections.Generic.List[hashtable]]::new()

function Add-SectionResult {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [ValidateSet('OK','SKIPPED','FAILED')] [string] $Status,
        [string] $Detail = ''
    )
    $script:SectionResults.Add(@{ Name = $Name; Status = $Status; Detail = $Detail })
}

function Write-FinalSummary {
    param([string]$ModeLabel, [bool]$IsWhatIf)

    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $title = if ($IsWhatIf) { "$ModeLabel — WhatIf summary (no changes made)" } else { "$ModeLabel — summary" }
    Write-Host "  $title" -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray

    $maxName = ($script:SectionResults | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
    if (-not $maxName) { $maxName = 20 }

    foreach ($r in $script:SectionResults) {
        $colour = switch ($r.Status) {
            'OK'      { 'Green' }
            'SKIPPED' { 'Yellow' }
            'FAILED'  { 'Red' }
        }
        $tag = "[$($r.Status)]".PadRight(10)
        $name = $r.Name.PadRight($maxName + 2)
        Write-Host ("   $tag $name") -ForegroundColor $colour -NoNewline
        if ($r.Detail) { Write-Host $r.Detail -ForegroundColor DarkGray } else { Write-Host '' }
    }

    $okCount      = @($script:SectionResults | Where-Object { $_.Status -eq 'OK' }).Count
    $skippedCount = @($script:SectionResults | Where-Object { $_.Status -eq 'SKIPPED' }).Count
    $failedCount  = @($script:SectionResults | Where-Object { $_.Status -eq 'FAILED' }).Count
    $total        = $script:SectionResults.Count

    Write-Host ""
    if ($failedCount -gt 0) {
        Write-Host "  $failedCount of $total SECTION(S) FAILED — review above." -ForegroundColor Red
    } elseif ($skippedCount -gt 0) {
        Write-Host "  $okCount/$total OK, $skippedCount SKIPPED — no failures, but not everything ran." -ForegroundColor Yellow
    } else {
        Write-Host "  ALL $total SECTIONS COMPLETED SUCCESSFULLY." -ForegroundColor Green
    }
    Write-Host ""

    # Set script-level exit code for the caller.
    if ($failedCount -gt 0) { $script:ExitCode = 2 }
    elseif ($skippedCount -gt 0) { $script:ExitCode = 0 }  # skips are intentional/known-limit
    else { $script:ExitCode = 0 }
}

$script:ExitCode = 0

# Collects explicit, copy-pasteable manual follow-up actions discovered during
# the run (e.g. the PhishSim portal step that can't be scripted). Printed as a
# single numbered block after the summary so the operator knows exactly what's
# left to do by hand.
$script:ManualSteps = [System.Collections.Generic.List[hashtable]]::new()

function Add-ManualStep {
    param(
        [Parameter(Mandatory)] [string]   $Title,
        [string[]] $Lines = @()
    )
    $script:ManualSteps.Add(@{ Title = $Title; Lines = $Lines })
}

# Convenience wrapper for the recurring PhishSim portal step. Locals like
# $refDomains aren't in scope here, so the caller passes them in.
function Add-PhishSimManualStep {
    param([string[]]$Domains = @(), [string[]]$IpRanges = @())
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("Open in a browser (signed in as the target tenant's admin):")
    $lines.Add("    https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation")
    $lines.Add("Select the 'Phishing simulation' tab, then click Edit (or Add).")
    $lines.Add("The flyout adds entries one at a time: type/paste a value and press Enter,")
    $lines.Add("then repeat. It does NOT split a comma- or semicolon-separated list.")
    $lines.Add("")
    $lines.Add("Under 'Sending domain', add these $($Domains.Count) (one per line):")
    if ($Domains.Count) { foreach ($d in $Domains) { $lines.Add("    $d") } }
    else                { $lines.Add("    (none in reference)") }
    $lines.Add("Under 'Sending IP', add these $($IpRanges.Count) (one per line):")
    if ($IpRanges.Count) { foreach ($ip in $IpRanges) { $lines.Add("    $ip") } }
    else                 { $lines.Add("    (none in reference)") }
    $lines.Add("Click Save when all entries are added.")
    $lines.Add("(The cmdlet API for this setting is blocked Microsoft-side, so it can't be scripted.)")
    Add-ManualStep -Title 'PhishSim advanced delivery: add sending domains + IPs via portal' -Lines $lines.ToArray()
}

function Write-ManualSteps {
    Write-Host ""
    if ($script:ManualSteps.Count -eq 0) {
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  MANUAL STEPS: none — the script applied everything." -ForegroundColor Green
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  MANUAL STEPS STILL REQUIRED — $($script:ManualSteps.Count) item(s)" -ForegroundColor Yellow
    Write-Host "  Do these by hand to finish onboarding this tenant:" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $i = 1
    foreach ($step in $script:ManualSteps) {
        Write-Host "  $i. $($step.Title)" -ForegroundColor White
        foreach ($ln in $step.Lines) {
            Write-Host "        $ln" -ForegroundColor Gray
        }
        Write-Host ""
        $i++
    }
}

#endregion

#region -- Interactive Setup Menu -----------------------------------------------
#
#  Two fields: mode (Export/Apply) + WhatIf (checkbox).
#  Navigation: ↑↓ navigate   space activate/toggle   enter run   esc cancel

function Show-SyncMenuFallback {
    [OutputType([hashtable])]
    param()

    Write-Host ""
    Write-Host "  SYNC-ALLOWLISTREPORT" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  A browser sign-in window will open after you confirm." -ForegroundColor DarkGray
    Write-Host "  Reads .\reference\* and merges values into the signed-in tenant." -ForegroundColor DarkGray
    Write-Host ""

    $iiRaw = (Read-Host "  Disable native Report Phishing and install Ironscales button? [Y/n]")
    $ii = -not ($iiRaw -match '^[nN]')   # default ON
    Write-Host ""
    $wi = (Read-Host "  WhatIf - dry run, no changes? [y/N]") -match '^[yY]'
    Write-Host ""

    return @{ WhatIf = $wi; InstallIronscales = $ii }
}

function Show-SyncMenu {
    [OutputType([hashtable])]
    param()

    $rawOk = $false
    try { $rawOk = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsInputRedirected } catch {}
    if (-not $rawOk) { return Show-SyncMenuFallback }

    $ESC = [char]27

    $installIs    = $true   # default: checked (onboarding intent)
    $whatIf       = $false
    $focus        = 0        # 0 = InstallIronscales   1 = WhatIf
    $done         = $false
    $cancel       = $false
    $lineCount    = 0
    $isFirst      = $true

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

    [Console]::Write("$ESC[?25l")

    try {
        while ($true) {

            $lines = [System.Collections.Generic.List[string]]::new()

            $lines.Add("")
            $lines.Add("  $ESC[96;1mSYNC-ALLOWLISTREPORT$ESC[0m")
            $lines.Add("  $ESC[90m────────────────────────────────────────────────────────$ESC[0m")
            $lines.Add("")
            $lines.Add("  $ESC[90mReads .\reference\* and merges values into the signed-in tenant.$ESC[0m")
            $lines.Add("  $ESC[90mA browser sign-in window will open when you press Enter.$ESC[0m")
            $lines.Add("")

            $lines.Add("  $ESC[90mOPTIONS$ESC[0m")
            $lines.Add("$(& $fp 0)$(& $cb $installIs)  $(& $fc 0)Disable native Report Phishing and install Ironscales button")
            $lines.Add("$(& $fp 1)$(& $cb $whatIf)  $(& $fc 1)WhatIf  $ESC[90m$ESC[2m(dry run -- no changes made)$ESC[0m")
            $lines.Add("")

            $lines.Add("  $ESC[90m────────────────────────────────────────────────────────$ESC[0m")
            $lines.Add("  $ESC[90m  up/down navigate   space toggle   enter run   esc cancel$ESC[0m")
            $lines.Add("")

            if (-not $isFirst) { [Console]::Write("$ESC[$($lineCount)A") }
            foreach ($ln in $lines) { [Console]::WriteLine("$ESC[2K$ln") }
            $lineCount = $lines.Count
            $isFirst   = $false

            if ($done -or $cancel) { break }

            $key = $null
            try { $key = [Console]::ReadKey($true) } catch { $cancel = $true; continue }

            $navItems = @(0, 1)
            $pos      = [Array]::IndexOf($navItems, $focus)

            switch ($key.Key) {
                ([ConsoleKey]::UpArrow)    { $pos = [Math]::Max(0, $pos - 1); $focus = $navItems[$pos] }
                ([ConsoleKey]::DownArrow)  { $pos = [Math]::Min($navItems.Length - 1, $pos + 1); $focus = $navItems[$pos] }
                ([ConsoleKey]::Spacebar) {
                    switch ($focus) {
                        0 { $installIs = -not $installIs }
                        1 { $whatIf    = -not $whatIf }
                    }
                }
                ([ConsoleKey]::Enter)  { $done = $true }
                ([ConsoleKey]::Escape) { $cancel = $true }
            }
        }
    } finally {
        [Console]::Write("$ESC[?25h")
    }

    if ($cancel) { return $null }

    return @{ WhatIf = $whatIf; InstallIronscales = $installIs }
}

#endregion

#region -- Reference File I/O ---------------------------------------------------

function Read-ReferenceList {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    return @(
        Get-Content -LiteralPath $Path -ErrorAction Stop |
            ForEach-Object { ($_ -split '#', 2)[0].Trim() } |
            Where-Object { $_ -ne '' }
    )
}

function Test-DomainLooksValid {
    param([string]$Value)
    return ($Value -match '^[A-Za-z0-9]([A-Za-z0-9\-\.]*[A-Za-z0-9])?$') -and ($Value -match '\.')
}

function Test-IpEntryLooksValid {
    param([string]$Value)
    # IPv4, IPv4 range (a.b.c.d-e.f.g.h), or CIDR /n
    if ($Value -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d{1,2})?$') { return $true }
    if ($Value -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}-\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { return $true }
    return $false
}

function Test-UrlEntryLooksValid {
    param([string]$Value)
    # Bare host or host with path/wildcards. Accepts modern TLDs (.email, .live, .online, etc.)
    return $Value -match '^[A-Za-z0-9][A-Za-z0-9\-\.]*\.[A-Za-z]{2,}(\/[^\s]*)?$'
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

# Show the TUI unless every option is already specified on the command line.
# WhatIf and InstallIronscales are the only options; if both are bound, skip.
$skipMenu = $PSBoundParameters.ContainsKey('WhatIf') -or $PSBoundParameters.ContainsKey('InstallIronscales')

if (-not $skipMenu) {
    Clear-Host
    $opts = Show-SyncMenu
    if ($null -eq $opts) {
        Write-Host "`n  Cancelled." -ForegroundColor DarkGray
        exit 0
    }
    if ($opts.WhatIf) { $WhatIfPreference = [System.Management.Automation.ActionPreference]::Continue }
    if (-not $PSBoundParameters.ContainsKey('InstallIronscales')) {
        $InstallIronscales = $opts.InstallIronscales
    }
}

$isWhatIf = ($WhatIfPreference -eq [System.Management.Automation.ActionPreference]::Continue) -or
            [bool]$PSBoundParameters['WhatIf']
if ([bool]$PSBoundParameters['WhatIf']) {
    $WhatIfPreference = [System.Management.Automation.ActionPreference]::Continue
}

# Resolve final InstallIronscales boolean. If neither parameter nor menu set it
# (e.g. non-interactive Apply with -Mode Apply and no -InstallIronscales), default ON.
if ($null -eq $InstallIronscales) { $InstallIronscales = $true }
$installIronscales = [bool]$InstallIronscales

#endregion

#region -- Connect --------------------------------------------------------------

Write-Step "Connecting to Exchange Online..."
Write-Host "   A browser sign-in window will open." -ForegroundColor DarkGray

# Tear down any existing session so we don't silently reuse a cached token
# from a previous run as a different account.
try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}

$connectParams = @{ ShowBanner = $false; ErrorAction = 'Stop' }
if ($SignInAs) {
    $connectParams.UserPrincipalName = $SignInAs
    Write-Host "   Pre-filling sign-in: $SignInAs" -ForegroundColor DarkGray
}

$connected = $false
try {
    Connect-ExchangeOnline @connectParams
    $connected = $true

    $orgName = try {
        (Get-OrganizationConfig -ErrorAction Stop).Name
    } catch { '(unknown)' }

    Write-OK "Connected to: $orgName"
} catch {
    Write-Fail "Connection failed: $_"
    Write-Host ""
    Write-Host "   Troubleshooting tips:" -ForegroundColor DarkGray
    Write-Host "   · Sign in with a Global Admin or Exchange Organization Management member." -ForegroundColor DarkGray
    exit 1
}

#endregion

try {

    Write-Step "Reading reference files..."

    if (-not (Test-Path -LiteralPath $ReferenceDir)) {
        Write-Fail "Reference folder not found: $ReferenceDir"
        Write-Host "   The script expects .\reference\* to be present alongside it." -ForegroundColor DarkGray
        exit 1
    }

    $refDomains   = @(Read-ReferenceList -Path $PhishSimDomainsFile)
    $refIpRanges  = @(Read-ReferenceList -Path $PhishSimIpRangesFile)
    $refUrls      = @(Read-ReferenceList -Path $PhishSimUrlsFile)
    $refConnIps   = @(Read-ReferenceList -Path $ConnFilterIpsFile)

    if (-not (Test-Path -LiteralPath $ReportSubmissionFile)) {
        Write-Fail "Missing reference file: $ReportSubmissionFile"
        exit 1
    }
    $rspRef = Get-Content -LiteralPath $ReportSubmissionFile -Raw | ConvertFrom-Json

    Write-OK "PhishSim domains:        $($refDomains.Count)"
    Write-OK "PhishSim IP ranges:      $($refIpRanges.Count)"
    Write-OK "PhishSim URLs:           $($refUrls.Count)"
    Write-OK "Connection filter IPs:   $($refConnIps.Count)"
    Write-OK "Report submission policy file loaded"

    # --- Validate format ---------------------------------------------------
    $badDomains  = @($refDomains   | Where-Object { -not (Test-DomainLooksValid $_) })
    $badPsIps    = @($refIpRanges  | Where-Object { -not (Test-IpEntryLooksValid $_) })
    $badUrls     = @($refUrls      | Where-Object { -not (Test-UrlEntryLooksValid $_) })
    $badConnIps  = @($refConnIps   | Where-Object { -not (Test-IpEntryLooksValid $_) })
    if ($badDomains.Count + $badPsIps.Count + $badUrls.Count + $badConnIps.Count -gt 0) {
        Write-Fail "Reference files contain malformed entries — aborting before any writes."
        if ($badDomains.Count) { Write-Host "   Bad domains:        $($badDomains -join ', ')" -ForegroundColor Red }
        if ($badPsIps.Count)   { Write-Host "   Bad PhishSim IPs:   $($badPsIps   -join ', ')" -ForegroundColor Red }
        if ($badUrls.Count)    { Write-Host "   Bad PhishSim URLs:  $($badUrls    -join ', ')" -ForegroundColor Red }
        if ($badConnIps.Count) { Write-Host "   Bad conn-filter IPs:$($badConnIps -join ', ')" -ForegroundColor Red }
        exit 1
    }

    Write-Host ""
    Write-Host "  Target tenant: $orgName" -ForegroundColor White
    if ($isWhatIf) { Write-Host "  WhatIf mode — no writes will be made." -ForegroundColor Yellow }
    Write-Host ""

    if (-not $isWhatIf) {
        $confirm = (Read-Host "  Apply allowlist values to '$orgName'? [Y/N]").Trim()
        if ($confirm -notmatch '^[Yy]') {
            Write-Warn "Cancelled — no changes made."
            exit 0
        }
    }

    # --- 1) PhishSim policy + rule (domains + sending IPs) ----------------
    #
    # Microsoft's Get-PhishSimOverridePolicy throws an opaque "server side
    # error" both for real RBAC failures AND for "no policy exists yet." We
    # can't distinguish from the message, so we try New- when Get- errors.
    # If New- succeeds, the Get was lying about empty. If New- fails with
    # "already exists", the policy does exist but RBAC blocks our reads. If
    # New- fails for another reason, we surface it.
    Write-Step "PhishSim advanced delivery (domains + sending IPs)..."
    $sectionDone = $false
    try {
        # --- Acquire policy ---
        $existingPolicy = $null
        try {
            $existingPolicy = Get-PhishSimOverridePolicy -ErrorAction Stop | Select-Object -First 1
        } catch {
            Write-Host "   Get-PhishSimOverridePolicy errored: $($_.Exception.Message)" -ForegroundColor DarkGray
            Write-Host "   Could mean 'no policy yet' or 'RBAC blocked' — attempting create to find out." -ForegroundColor DarkGray
        }

        if (-not $existingPolicy) {
            if ($PSCmdlet.ShouldProcess($PhishSimPolicyName, "New-PhishSimOverridePolicy")) {
                try {
                    $existingPolicy = New-PhishSimOverridePolicy -Name $PhishSimPolicyName -ErrorAction Stop
                    Write-OK "Created policy: $PhishSimPolicyName"
                } catch {
                    $msg = $_.Exception.Message
                    if ($msg -match 'already exists|already configured|with the same name|conflict') {
                        Write-Warn "Policy already exists but Get- can't read it (RBAC asymmetry)."
                        Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status SKIPPED `
                            -Detail "Policy exists but cmdlet reads blocked. Configure via portal: https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation"
                        Add-PhishSimManualStep -Domains $refDomains -IpRanges $refIpRanges
                        $sectionDone = $true
                    } elseif ($msg -match 'A server side error has occurred') {
                        # Both Get- AND New- return the same opaque 403/error. This
                        # is a known Microsoft-side authorization gap on the
                        # PhishSim Advanced Delivery cmdlet — not fixable from
                        # PowerShell even for Global Administrators who are direct
                        # members of Organization Management AND Security
                        # Administrator role groups with Defender XDR Unified RBAC
                        # inactive. Confirmed against multiple tenants. Use portal.
                        Write-Warn "PhishSim cmdlets are blocked on this tenant (both Get and New return 403)."
                        Write-Warn "This is a Microsoft-side limitation — even Global Admins are affected."
                        Write-Warn "Configure manually at:"
                        Write-Host  "   https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation" -ForegroundColor Cyan
                        Write-Host  "   - Add domains:    $($refDomains  -join ', ')" -ForegroundColor DarkGray
                        Write-Host  "   - Add sending IPs: $($refIpRanges -join ', ')" -ForegroundColor DarkGray
                        Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status SKIPPED `
                            -Detail "Cmdlet API blocked (Microsoft-side). Configure $($refDomains.Count) domain(s) + $($refIpRanges.Count) IP(s) via portal."
                        Add-PhishSimManualStep -Domains $refDomains -IpRanges $refIpRanges
                        $sectionDone = $true
                    } else {
                        # Genuinely unexpected — surface as FAILED
                        throw
                    }
                }
            } else {
                Write-Host "   [WhatIf] Would attempt to create policy: $PhishSimPolicyName" -ForegroundColor DarkGray
            }
        } else {
            Write-OK "Policy exists: $($existingPolicy.Name)"
            if ($existingPolicy.Enabled -ne $true) {
                if ($PSCmdlet.ShouldProcess($existingPolicy.Name, "Set-PhishSimOverridePolicy -Enabled `$true")) {
                    Set-PhishSimOverridePolicy -Identity $existingPolicy.Identity -Enabled $true -ErrorAction Stop
                    Write-OK "Enabled policy."
                }
            }
        }

        # --- Acquire rule (same Get/New fallback pattern) ---
        if (-not $sectionDone) {
            $existingRule = $null
            try {
                $existingRule = Get-ExoPhishSimOverrideRule -ErrorAction Stop | Select-Object -First 1
            } catch {
                Write-Host "   Get-ExoPhishSimOverrideRule errored: $($_.Exception.Message)" -ForegroundColor DarkGray
            }

            $addedDomains = 0; $addedIpRanges = 0
            if (-not $existingRule) {
                if ($refIpRanges.Count -eq 0) {
                    Write-Warn "Reference has no IP ranges — cannot create rule (SenderIpRanges is mandatory). Skipping."
                    Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status SKIPPED `
                        -Detail "Reference has no IP ranges; rule cannot be created"
                    Add-ManualStep -Title 'PhishSim advanced delivery: reference file is missing IP ranges' -Lines @(
                        "The PhishSim rule needs at least one sending IP, but reference/phishsim-ipranges.txt is empty.",
                        "Add the vendor's sending IPs/ranges to that file and re-run this script,",
                        "or configure them directly in the portal:",
                        "    https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation"
                    )
                    $sectionDone = $true
                } elseif ($PSCmdlet.ShouldProcess('(new PhishSim rule)', "New-ExoPhishSimOverrideRule")) {
                    $newRuleParams = @{
                        Policy         = $PhishSimPolicyName
                        SenderIpRanges = $refIpRanges
                    }
                    if ($refDomains.Count -gt 0) { $newRuleParams.Domains = $refDomains }
                    try {
                        New-ExoPhishSimOverrideRule @newRuleParams -ErrorAction Stop | Out-Null
                        Write-OK "Created rule with $($refDomains.Count) domain(s), $($refIpRanges.Count) IP range(s)."
                        $addedDomains  = $refDomains.Count
                        $addedIpRanges = $refIpRanges.Count
                    } catch {
                        $msg = $_.Exception.Message
                        if ($msg -match 'already exists|already configured|with the same name|conflict') {
                            Write-Warn "Rule already exists but Get- couldn't read it (RBAC). Can't merge missing entries."
                            Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status SKIPPED `
                                -Detail "Rule exists but cmdlet reads blocked. Configure via portal: https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation"
                            Add-PhishSimManualStep -Domains $refDomains -IpRanges $refIpRanges
                            $sectionDone = $true
                        } elseif ($msg -match 'A server side error has occurred') {
                            Write-Warn "PhishSim rule cmdlets are blocked on this tenant (Microsoft-side limitation)."
                            Write-Host  "   Configure manually at: https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation" -ForegroundColor Cyan
                            Write-Host  "   - Add domains:    $($refDomains  -join ', ')" -ForegroundColor DarkGray
                            Write-Host  "   - Add sending IPs: $($refIpRanges -join ', ')" -ForegroundColor DarkGray
                            Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status SKIPPED `
                                -Detail "Cmdlet API blocked (Microsoft-side). Configure $($refDomains.Count) domain(s) + $($refIpRanges.Count) IP(s) via portal."
                            Add-PhishSimManualStep -Domains $refDomains -IpRanges $refIpRanges
                            $sectionDone = $true
                        } else {
                            throw
                        }
                    }
                } else {
                    Write-Host "   [WhatIf] Would create rule with $($refDomains.Count) domain(s), $($refIpRanges.Count) IP range(s)." -ForegroundColor DarkGray
                }
            } else {
                $curDomains  = @($existingRule.SenderDomainIs)
                $curIpRanges = @($existingRule.SenderIpRanges)
                $missingDomains  = @($refDomains  | Where-Object { $_ -notin $curDomains })
                $missingIpRanges = @($refIpRanges | Where-Object { $_ -notin $curIpRanges })

                Write-Host "   Current: $($curDomains.Count) domain(s), $($curIpRanges.Count) IP range(s)" -ForegroundColor DarkGray
                Write-Host "   Missing: $($missingDomains.Count) domain(s), $($missingIpRanges.Count) IP range(s)" -ForegroundColor DarkGray

                if ($missingDomains.Count -eq 0 -and $missingIpRanges.Count -eq 0) {
                    Write-OK "Already up to date."
                } else {
                    $setParams = @{ Identity = $existingRule.Identity }
                    if ($missingDomains.Count  -gt 0) { $setParams.AddSenderDomainIs = $missingDomains }
                    if ($missingIpRanges.Count -gt 0) { $setParams.AddSenderIpRanges = $missingIpRanges }
                    if ($PSCmdlet.ShouldProcess($existingRule.Name, "Set-ExoPhishSimOverrideRule Add...")) {
                        Set-ExoPhishSimOverrideRule @setParams -ErrorAction Stop
                        Write-OK "Added $($missingDomains.Count) domain(s), $($missingIpRanges.Count) IP range(s)."
                        $addedDomains  = $missingDomains.Count
                        $addedIpRanges = $missingIpRanges.Count
                    } else {
                        Write-Host "   [WhatIf] Would add $($missingDomains.Count) domain(s), $($missingIpRanges.Count) IP range(s)." -ForegroundColor DarkGray
                    }
                }
            }

            if (-not $sectionDone) {
                $detail = if ($isWhatIf) { "WhatIf — no writes" }
                          elseif ($addedDomains -eq 0 -and $addedIpRanges -eq 0) { "already in sync" }
                          else { "added $addedDomains domain(s), $addedIpRanges IP range(s)" }
                Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status OK -Detail $detail
            }
        }
    } catch {
        Write-Fail "PhishSim policy/rule section failed: $($_.Exception.Message)"
        Add-SectionResult -Name 'PhishSim policy+rule (domains/IPs)' -Status FAILED -Detail $_.Exception.Message
    }

    # --- 2) PhishSim URLs (Tenant Allow/Block List) -----------------------
    Write-Step "PhishSim allowed simulation URLs..."
    try {
        if ($refUrls.Count -eq 0) {
            Write-Warn "Reference has no URLs — skipping."
            Add-SectionResult -Name 'PhishSim allowed-simulation URLs' -Status SKIPPED `
                -Detail "Reference file has no URLs"
        } else {
            $curUrls = @(Get-TenantAllowBlockListItems -ListType Url -ListSubType AdvancedDelivery -ErrorAction Stop |
                Select-Object -ExpandProperty Value)
            $missingUrls = @($refUrls | Where-Object { $_ -notin $curUrls })

            Write-Host "   Current: $($curUrls.Count) URL(s)" -ForegroundColor DarkGray
            Write-Host "   Missing: $($missingUrls.Count) URL(s)" -ForegroundColor DarkGray

            $added = 0
            if ($missingUrls.Count -eq 0) {
                Write-OK "Already up to date."
            } elseif ($PSCmdlet.ShouldProcess("$($missingUrls.Count) URL(s)", "New-TenantAllowBlockListItems Url AdvancedDelivery")) {
                New-TenantAllowBlockListItems -ListType Url -ListSubType AdvancedDelivery `
                    -Entries $missingUrls -Allow -NoExpiration -ErrorAction Stop | Out-Null
                Write-OK "Added $($missingUrls.Count) URL(s)."
                $added = $missingUrls.Count
            } else {
                Write-Host "   [WhatIf] Would add $($missingUrls.Count) URL(s)." -ForegroundColor DarkGray
            }

            $detail = if ($isWhatIf) { "WhatIf — $($missingUrls.Count) would be added" }
                      elseif ($added -eq 0) { "already in sync ($($curUrls.Count) entries)" }
                      else { "added $added URL(s)" }
            Add-SectionResult -Name 'PhishSim allowed-simulation URLs' -Status OK -Detail $detail
        }
    } catch {
        Write-Fail "PhishSim URLs section failed: $($_.Exception.Message)"
        Add-SectionResult -Name 'PhishSim allowed-simulation URLs' -Status FAILED -Detail $_.Exception.Message
    }

    # --- 3) Connection filter IP allow list -------------------------------
    Write-Step "Connection filter policy ($ConnFilterPolicyName)..."
    try {
        $cf = Get-HostedConnectionFilterPolicy -Identity $ConnFilterPolicyName -ErrorAction Stop
        $curConnIps     = @($cf.IPAllowList)
        $missingConnIps = @($refConnIps | Where-Object { $_ -notin $curConnIps })

        Write-Host "   Current: $($curConnIps.Count) IP(s)" -ForegroundColor DarkGray
        Write-Host "   Missing: $($missingConnIps.Count) IP(s)" -ForegroundColor DarkGray

        $added = 0
        if ($missingConnIps.Count -eq 0) {
            Write-OK "Already up to date."
        } elseif ($PSCmdlet.ShouldProcess($ConnFilterPolicyName, "Set-HostedConnectionFilterPolicy IPAllowList Add")) {
            Set-HostedConnectionFilterPolicy -Identity $ConnFilterPolicyName `
                -IPAllowList @{Add = $missingConnIps} -ErrorAction Stop
            Write-OK "Added $($missingConnIps.Count) IP(s)."
            $added = $missingConnIps.Count
        } else {
            Write-Host "   [WhatIf] Would add $($missingConnIps.Count) IP(s)." -ForegroundColor DarkGray
        }

        $detail = if ($isWhatIf) { "WhatIf — $($missingConnIps.Count) would be added" }
                  elseif ($added -eq 0) { "already in sync ($($curConnIps.Count) entries)" }
                  else { "added $added IP(s)" }
        Add-SectionResult -Name 'Connection filter IP allow list' -Status OK -Detail $detail
    } catch {
        Write-Fail "Connection filter section failed: $($_.Exception.Message)"
        Add-SectionResult -Name 'Connection filter IP allow list' -Status FAILED -Detail $_.Exception.Message
    }

    # --- 4) Report submission policy --------------------------------------
    Write-Step "Report submission policy (disable native button)..."
    if (-not $installIronscales) {
        Write-Warn "Checkbox unchecked — leaving native Report Phishing button enabled."
        Add-SectionResult -Name 'Report submission policy (disable native)' -Status SKIPPED `
            -Detail "Native Report Phishing left enabled (checkbox not selected)"
    } else {
    try {
        $rspParams = @{ Identity = $ReportSubmissionPolicy }
        foreach ($field in $ReportSubmissionFields) {
            if ($rspRef.PSObject.Properties.Name -contains $field) {
                $rspParams[$field] = $rspRef.$field
            }
        }

        if ($PSCmdlet.ShouldProcess($ReportSubmissionPolicy, "Set-ReportSubmissionPolicy (disable native)")) {
            Set-ReportSubmissionPolicy @rspParams -ErrorAction Stop
            Write-OK "Applied $($ReportSubmissionFields.Count) toggle(s)."
        } else {
            Write-Host "   [WhatIf] Would apply $($ReportSubmissionFields.Count) toggle(s)." -ForegroundColor DarkGray
        }

        $removeRule = $false
        if ($rspRef.PSObject.Properties.Name -contains 'RemoveSubmissionRule') {
            $removeRule = [bool]$rspRef.RemoveSubmissionRule
        }
        $removedCount = 0
        if ($removeRule) {
            $existingSubRules = @(Get-ReportSubmissionRule -ErrorAction SilentlyContinue)
            if ($existingSubRules.Count -eq 0) {
                Write-OK "No report submission rule to remove."
            } elseif ($PSCmdlet.ShouldProcess("$($existingSubRules.Count) rule(s)", "Remove-ReportSubmissionRule")) {
                foreach ($r in $existingSubRules) {
                    Remove-ReportSubmissionRule -Identity $r.Identity -Confirm:$false -ErrorAction Stop
                    Write-OK "Removed rule: $($r.Name)"
                    $removedCount++
                }
            } else {
                Write-Host "   [WhatIf] Would remove $($existingSubRules.Count) rule(s)." -ForegroundColor DarkGray
            }
        }

        $detail = if ($isWhatIf) { "WhatIf — would set 9 toggle(s)" }
                  elseif ($removedCount -gt 0) { "set 9 toggle(s); removed $removedCount existing rule(s)" }
                  else { "set 9 toggle(s); no rule to remove" }
        Add-SectionResult -Name 'Report submission policy (disable native)' -Status OK -Detail $detail
    } catch {
        Write-Fail "Report submission section failed: $($_.Exception.Message)"
        Add-SectionResult -Name 'Report submission policy (disable native)' -Status FAILED -Detail $_.Exception.Message
    }
    }  # end of if ($installIronscales) for section 4

    # --- 5) Ironscales Report Phishing OWA add-in (Centralized Deployment) ---
    Write-Step "Ironscales Report Phishing OWA add-in..."
    if (-not $installIronscales) {
        Write-Warn "Checkbox unchecked — Ironscales add-in not installed."
        Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
            -Detail "Ironscales add-in not installed (checkbox not selected)"
    } else {
        $cdConnected = $false
        try {
            # --- Prereq checks (any failure -> SKIPPED, no tenant writes) ---
            if (-not (Test-Path -LiteralPath $IronscalesManifestFile)) {
                Write-Warn "Manifest not found: $IronscalesManifestFile"
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
                    -Detail "Manifest file not found in reference/"
                throw 'skip-section'
            }

            try {
                $manifestXml = [xml](Get-Content -LiteralPath $IronscalesManifestFile -Raw -ErrorAction Stop)
                $productId   = $manifestXml.OfficeApp.Id
            } catch {
                Write-Warn "Could not parse manifest XML: $($_.Exception.Message)"
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
                    -Detail "Manifest XML parse failed"
                throw 'skip-section'
            }
            if ([string]::IsNullOrWhiteSpace($productId)) {
                Write-Warn "Manifest has no <Id> — cannot identify add-in."
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
                    -Detail "Manifest <Id> empty"
                throw 'skip-section'
            }
            Write-Host "   Manifest <Id>: $productId" -ForegroundColor DarkGray

            $appsEnabled = $false
            try { $appsEnabled = [bool](Get-OrganizationConfig -ErrorAction Stop).AppsForOfficeEnabled } catch {}
            if (-not $appsEnabled) {
                Write-Warn "Tenant has AppsForOfficeEnabled = `$false. Add-ins are disabled org-wide."
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
                    -Detail "AppsForOfficeEnabled is `$false on this tenant"
                throw 'skip-section'
            }

            # --- Legacy New-App conflict guard (won't auto-fix per design) ---
            $legacyHit = $null
            try {
                $legacyHit = Get-App -OrganizationApp -ErrorAction SilentlyContinue |
                    Where-Object { $_.AppId -eq $productId } | Select-Object -First 1
            } catch {}
            if ($legacyHit) {
                Write-Warn "Add-in already installed via legacy New-App path (AppId $productId)."
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
                    -Detail "Legacy New-App install detected; remove with Remove-App -Identity $($legacyHit.AppId), then re-run"
                Add-ManualStep -Title 'Ironscales add-in: remove the legacy install, then re-run' -Lines @(
                    "This tenant already has the add-in installed via the old New-App path,",
                    "so the modern Centralized Deployment install was skipped to avoid two buttons.",
                    "Run this (in the EXO session), then re-run this script:",
                    "    Remove-App -Identity $($legacyHit.AppId) -OrganizationApp"
                )
                throw 'skip-section'
            }

            # --- Module bootstrap ---
            if (-not (Get-Module -ListAvailable -Name O365CentralizedAddInDeployment)) {
                Write-Warn "O365CentralizedAddInDeployment not found — installing..."
                Install-Module -Name O365CentralizedAddInDeployment -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-OK "Module installed."
            }
            Import-Module O365CentralizedAddInDeployment -ErrorAction Stop

            # --- Connect (separate auth context from EXO; requires Global Admin) ---
            # Connect-OrganizationAddInService only accepts -Credential (basic auth)
            # and -Url. With neither, it opens a browser sign-in. The cmdlet has no
            # way to pre-fill a UPN; if $SignInAs was set, tell the user which
            # account to pick in the popup.
            if ($SignInAs) {
                Write-Host "   Sign in with: $SignInAs (must be Global Administrator)" -ForegroundColor DarkGray
            }
            try {
                Connect-OrganizationAddInService -ErrorAction Stop | Out-Null
                $cdConnected = $true
                Write-OK "Connected to Centralized Deployment service."
            } catch {
                Write-Warn "Connect-OrganizationAddInService failed: $($_.Exception.Message)"
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status SKIPPED `
                    -Detail "Connect-OrganizationAddInService failed (requires Global Admin)"
                throw 'skip-section'
            }

            # --- Idempotency check + install + assign ---
            $existing = $null
            try {
                $existing = Get-OrganizationAddIn -ErrorAction Stop |
                    Where-Object { $_.ProductId -eq $productId } | Select-Object -First 1
            } catch {
                Write-Warn "Get-OrganizationAddIn failed: $($_.Exception.Message)"
            }

            $assignedToEveryone = $false
            if ($existing) {
                Write-OK "Add-in already present (ProductId $productId)."
                # The O365CentralizedAddInDeployment module has no Get-…Assignments
                # cmdlet; assignment info lives on the Get-OrganizationAddIn object.
                # "Assigned to everyone" means: no specific groups/users AND a
                # default state that makes it active (Enabled / Mandatory / AlwaysEnabled).
                $hasGroups = $existing.AssignedGroups -and @($existing.AssignedGroups).Count -gt 0
                $hasUsers  = $existing.AssignedUsers  -and @($existing.AssignedUsers).Count -gt 0
                $activeDefault = $existing.DefaultStateForUser -in @('Enabled','Mandatory','AlwaysEnabled')
                $assignedToEveryone = (-not $hasGroups) -and (-not $hasUsers) -and $activeDefault
                Write-Host "   DefaultStateForUser=$($existing.DefaultStateForUser); AssignedGroups=$(if($hasGroups){'set'}else{'(none)'}); AssignedUsers=$(if($hasUsers){'set'}else{'(none)'})" -ForegroundColor DarkGray
            }

            $action = 'none'
            if (-not $existing) {
                if ($PSCmdlet.ShouldProcess('Ironscales add-in', "New-OrganizationAddIn")) {
                    New-OrganizationAddIn -ManifestPath $IronscalesManifestFile -Locale 'en-US' -ErrorAction Stop | Out-Null
                    Write-OK "Uploaded manifest."
                    $action = 'installed'
                } else {
                    Write-Host "   [WhatIf] Would upload manifest." -ForegroundColor DarkGray
                    $action = 'whatif-install'
                }
            }

            if (-not $assignedToEveryone) {
                if ($PSCmdlet.ShouldProcess($productId, "Set-OrganizationAddInAssignments -AssignToEveryone `$true")) {
                    Set-OrganizationAddInAssignments -ProductId $productId -AssignToEveryone $true -ErrorAction Stop | Out-Null
                    Write-OK "Assigned to everyone."
                    if ($action -eq 'installed') { $action = 'installed+assigned' }
                    elseif ($action -eq 'none')  { $action = 'reassigned' }
                } else {
                    Write-Host "   [WhatIf] Would assign to everyone." -ForegroundColor DarkGray
                    if ($action -eq 'whatif-install') { $action = 'whatif-install+assign' }
                    elseif ($action -eq 'none')        { $action = 'whatif-reassign' }
                }
            } elseif ($action -eq 'none') {
                Write-OK "Already assigned to everyone — nothing to do."
                $action = 'idempotent'
            }

            $detail = switch ($action) {
                'installed+assigned'      { "installed + assigned to everyone (client propagation 24–72h)" }
                'installed'               { "installed (assignment skipped); client propagation 24–72h" }
                'reassigned'              { "already installed; updated assignment to everyone" }
                'idempotent'              { "already installed and assigned to everyone" }
                'whatif-install+assign'   { "WhatIf — would install + assign to everyone" }
                'whatif-install'          { "WhatIf — would install" }
                'whatif-reassign'         { "WhatIf — would update assignment to everyone" }
                default                   { "no action" }
            }
            Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status OK -Detail $detail
        } catch {
            if ("$_" -ne 'skip-section') {
                Write-Fail "Ironscales add-in section failed: $($_.Exception.Message)"
                Add-SectionResult -Name 'Ironscales add-in (org-wide)' -Status FAILED -Detail $_.Exception.Message
            }
        }
        # No Disconnect-OrganizationAddInService cmdlet exists in this module —
        # the session lives in the process and is released when the script ends.
    }

    Write-FinalSummary -ModeLabel "Apply against '$orgName'" -IsWhatIf $isWhatIf
    Write-ManualSteps

} finally {
    if ($connected) {
        Write-Step "Disconnecting..."
        try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue; Write-OK "Disconnected." } catch {}
    }
    Write-Host ""
}

exit $script:ExitCode
