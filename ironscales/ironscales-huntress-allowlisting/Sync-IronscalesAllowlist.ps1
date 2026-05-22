#Requires -Version 5.1
<#
.SYNOPSIS
    Allowlist Curricula simulation domains and IPs in an IronScales tenant.

.DESCRIPTION
    Reads domains.txt and ips.txt and ensures each entry exists in
    Settings -> Threat Protection -> Allow List (same backend list as
    Settings -> Simulation & Training -> Ignore IP Range) with:

      - Scope = "Skip All Inspections"           (scope: 1)
      - Ignore SPF/DKIM/DMARC + int/ext auth     (ignore_auth: true)
      - Show response message for external camp. (external_campaigns: true)

    Re-runs are idempotent: POSTs missing entries, PUTs entries with wrong
    flags, leaves correct entries untouched.

    Every run is one-shot: the Company ID and Company Token are entered
    interactively (or via parameters) and held in-memory only. Nothing is
    written to disk.

    Note: the Simulation Mail Reported text (Settings -> Threat Protection
    -> Report Phishing Add-on (O365) -> Simulation Mail Reported) is NOT
    exposed by the AppAPI. The script prints the exact UI steps and text
    to paste at the end.

.PARAMETER CompanyId
    IronScales company ID for the target tenant. If omitted, you'll be
    prompted at runtime.

.PARAMETER DomainsFile
    Path to a newline-delimited list of domains. Blank lines and lines
    starting with '#' are ignored.

.PARAMETER IpsFile
    Path to a newline-delimited list of IPs or CIDR ranges.

.PARAMETER Comment
    Comment written on newly created allow-list entries.

.PARAMETER DryRun
    Show the diff (ADD / UPDATE) without calling POST or PUT. If not
    specified on the command line, you'll be prompted to choose LIVE or
    DRY RUN at runtime.

.EXAMPLE
    .\ironscales-huntress-allowlisting.ps1
    # Prompts for Company ID and mode.

.EXAMPLE
    .\ironscales-huntress-allowlisting.ps1 -CompanyId 12345 -DryRun
    # Non-interactive dry run.

.EXAMPLE
    .\ironscales-huntress-allowlisting.ps1 -CompanyId 12345 -DryRun:$false
    # Non-interactive live run.
#>
[CmdletBinding()]
param(
    [string]$CompanyId,
    [string]$DomainsFile = (Join-Path $PSScriptRoot 'domains.txt'),
    [string]$IpsFile     = (Join-Path $PSScriptRoot 'ips.txt'),
    [string]$Comment     = 'Curricula simulation allowlist',
    [switch]$DryRun
)

$DryRunExplicit = $PSBoundParameters.ContainsKey('DryRun')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$BaseUrl                 = 'https://appapi.ironscales.com/appapi'
$EntryTypeIp             = 1
$EntryTypeDomain         = 2
$DesiredScope            = 1
$DesiredIgnoreAuth       = $true
$DesiredExternalCampaigns = $true

function Read-ApiKey {
    Write-Host 'Enter the Company Token for this tenant' -ForegroundColor Yellow
    Write-Host '  (IronScales web UI -> Settings -> General -> Company Token):' -ForegroundColor Yellow
    $secure = Read-Host -Prompt 'Company Token' -AsSecureString
    if (-not $secure -or $secure.Length -eq 0) { throw 'No API key provided.' }

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-IronscalesJwt {
    param([Parameter(Mandatory=$true)][string]$Key)

    $body = @{ key = $Key; scopes = @('company.view', 'company.edit') } | ConvertTo-Json -Depth 4 -Compress
    $uri  = "$BaseUrl/get-token/"

    foreach ($authValue in @($Key, "Bearer $Key")) {
        $headers = @{ Authorization = $authValue; 'Content-Type' = 'application/json' }
        try {
            $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -TimeoutSec 30
            if ($resp -and $resp.jwt) { return $resp.jwt }
            throw 'Token response did not include a jwt field.'
        } catch {
            $status = $null
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            if ($status -in 401, 403 -and $authValue -eq $Key) {
                continue
            }
            $detail = $_.ErrorDetails.Message
            if (-not $detail) { $detail = $_.Exception.Message }
            throw "Authentication to /get-token/ failed (HTTP $status). Response: $detail"
        }
    }
    throw 'Authentication to /get-token/ failed for both raw and Bearer header forms.'
}

function Get-AllowList {
    param(
        [Parameter(Mandatory=$true)][string]$Jwt,
        [Parameter(Mandatory=$true)][string]$CompanyId
    )

    $headers = @{ Authorization = "Bearer $Jwt" }
    $all = New-Object System.Collections.Generic.List[object]
    $page = 1
    while ($true) {
        $uri  = "$BaseUrl/settings/$CompanyId/allow-list/?type=all&items_per_page=500&page=$page"
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -TimeoutSec 60
        if ($resp -and $resp.PSObject.Properties.Name -contains 'allow_list' -and $resp.allow_list) {
            foreach ($e in $resp.allow_list) { $all.Add($e) | Out-Null }
        }
        $pagesCount = 0
        if ($resp -and $resp.PSObject.Properties.Name -contains 'pages_count' -and $resp.pages_count) {
            $pagesCount = [int]$resp.pages_count
        }
        if ($pagesCount -le $page) { break }
        $page++
    }
    return ,$all.ToArray()
}

function Add-AllowListEntry {
    param(
        [Parameter(Mandatory=$true)][string]$Jwt,
        [Parameter(Mandatory=$true)][string]$CompanyId,
        [Parameter(Mandatory=$true)][int]$Type,
        [Parameter(Mandatory=$true)][string]$Value,
        [string]$Comment
    )

    $body = @{
        type               = $Type
        value              = $Value
        scope              = $DesiredScope
        ignore_auth        = $DesiredIgnoreAuth
        external_campaigns = $DesiredExternalCampaigns
        comment            = $Comment
    } | ConvertTo-Json -Depth 4 -Compress

    $headers = @{ Authorization = "Bearer $Jwt"; 'Content-Type' = 'application/json' }
    Invoke-RestMethod -Method Post -Uri "$BaseUrl/settings/$CompanyId/allow-list/" `
        -Headers $headers -Body $body -TimeoutSec 60 | Out-Null
}

function Update-AllowListEntry {
    param(
        [Parameter(Mandatory=$true)][string]$Jwt,
        [Parameter(Mandatory=$true)][string]$CompanyId,
        [Parameter(Mandatory=$true)][int]$SelectedId,
        [Parameter(Mandatory=$true)][int]$Type,
        [Parameter(Mandatory=$true)][string]$Value
    )

    $body = @{
        selected_id        = $SelectedId
        type               = $Type
        value              = $Value
        scope              = $DesiredScope
        ignore_auth        = $DesiredIgnoreAuth
        external_campaigns = $DesiredExternalCampaigns
    } | ConvertTo-Json -Depth 4 -Compress

    $headers = @{ Authorization = "Bearer $Jwt"; 'Content-Type' = 'application/json' }
    Invoke-RestMethod -Method Put -Uri "$BaseUrl/settings/$CompanyId/allow-list/" `
        -Headers $headers -Body $body -TimeoutSec 60 | Out-Null
}

function Read-DesiredEntries {
    param(
        [Parameter(Mandatory=$true)][string]$DomainsPath,
        [Parameter(Mandatory=$true)][string]$IpsPath
    )

    $list = New-Object System.Collections.Generic.List[object]

    if (Test-Path -LiteralPath $DomainsPath) {
        Get-Content -LiteralPath $DomainsPath | ForEach-Object {
            $v = $_.Trim()
            if (-not $v -or $v.StartsWith('#')) { return }
            $list.Add([pscustomobject]@{ Type = $EntryTypeDomain; Value = $v.ToLowerInvariant() }) | Out-Null
        }
    } else {
        Write-Warning "Domains file not found: $DomainsPath"
    }

    if (Test-Path -LiteralPath $IpsPath) {
        Get-Content -LiteralPath $IpsPath | ForEach-Object {
            $v = $_.Trim()
            if (-not $v -or $v.StartsWith('#')) { return }
            $list.Add([pscustomobject]@{ Type = $EntryTypeIp; Value = $v }) | Out-Null
        }
    } else {
        Write-Warning "IPs file not found: $IpsPath"
    }

    return ,$list.ToArray()
}

function Format-HttpError {
    param($ErrorRecord)
    $msg = $ErrorRecord.Exception.Message
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
        $msg = "$msg :: $($ErrorRecord.ErrorDetails.Message)"
    }
    return $msg
}

# --- Main -------------------------------------------------------------------

if (-not $CompanyId -or [string]::IsNullOrWhiteSpace($CompanyId)) {
    $CompanyId = (Read-Host -Prompt 'IronScales Company ID').Trim()
    if (-not $CompanyId) { throw 'No Company ID provided.' }
}

if (-not $DryRunExplicit) {
    Write-Host ''
    Write-Host 'Choose run mode:' -ForegroundColor Cyan
    Write-Host '  [L] LIVE     - apply changes (POST/PUT to IronScales)'
    Write-Host '  [D] DRY RUN  - preview changes without applying (default)'
    $choice = (Read-Host -Prompt 'Mode (L/D)').Trim().ToUpperInvariant()
    if ($choice -eq 'L' -or $choice -eq 'LIVE') {
        $DryRun = $false
        Write-Host 'Mode: LIVE' -ForegroundColor Yellow
    } else {
        $DryRun = $true
        Write-Host 'Mode: DRY RUN' -ForegroundColor Green
    }
}

$apiKey = Read-ApiKey

Write-Host 'Requesting JWT...' -ForegroundColor Cyan
$jwt = Get-IronscalesJwt -Key $apiKey
$apiKey = $null

$desired = Read-DesiredEntries -DomainsPath $DomainsFile -IpsPath $IpsFile
if (-not $desired -or $desired.Count -eq 0) { throw 'No entries found in input files.' }
Write-Host ("Loaded {0} desired entries from {1} and {2}." -f $desired.Count, (Split-Path -Leaf $DomainsFile), (Split-Path -Leaf $IpsFile)) -ForegroundColor Cyan

Write-Host "Fetching current allow-list for company $CompanyId..." -ForegroundColor Cyan
$current = Get-AllowList -Jwt $jwt -CompanyId $CompanyId
Write-Host ("Current list has {0} entries." -f $current.Count) -ForegroundColor Cyan

$lookup = @{}
foreach ($e in $current) {
    $val = ''
    if ($e.PSObject.Properties.Name -contains 'value' -and $e.value) {
        $val = ([string]$e.value).ToLowerInvariant()
    }
    $t = 0
    if ($e.PSObject.Properties.Name -contains 'type' -and $e.type) {
        $t = [int]$e.type
    }
    $k = "$t|$val"
    $lookup[$k] = $e
}

$added = 0; $updated = 0; $alreadyCorrect = 0; $errors = 0

foreach ($d in $desired) {
    $key = "$($d.Type)|$(([string]$d.Value).ToLowerInvariant())"

    if ($lookup.ContainsKey($key)) {
        $existing  = $lookup[$key]
        $curScope  = if ($existing.PSObject.Properties.Name -contains 'scope') { [int]$existing.scope } else { -1 }
        $curIgnAu  = if ($existing.PSObject.Properties.Name -contains 'ignore_auth') { [bool]$existing.ignore_auth } else { $false }
        $curExtCmp = if ($existing.PSObject.Properties.Name -contains 'external_campaigns') { [bool]$existing.external_campaigns } else { $false }

        $needsUpdate = ($curScope -ne $DesiredScope) `
                    -or ($curIgnAu -ne $DesiredIgnoreAuth) `
                    -or ($curExtCmp -ne $DesiredExternalCampaigns)

        if ($needsUpdate) {
            if ($DryRun) {
                Write-Host ("[DRY] UPDATE {0,-40} (id={1}, scope={2}->{3}, ignore_auth={4}->{5}, external_campaigns={6}->{7})" `
                    -f $d.Value, $existing.id, $curScope, $DesiredScope, $curIgnAu, $DesiredIgnoreAuth, $curExtCmp, $DesiredExternalCampaigns) `
                    -ForegroundColor Yellow
            } else {
                try {
                    Update-AllowListEntry -Jwt $jwt -CompanyId $CompanyId -SelectedId ([int]$existing.id) -Type $d.Type -Value $d.Value
                    Write-Host ("  UPDATED  {0}" -f $d.Value) -ForegroundColor Yellow
                } catch {
                    Write-Host ("  ERROR    {0}: {1}" -f $d.Value, (Format-HttpError $_)) -ForegroundColor Red
                    $errors++
                    continue
                }
            }
            $updated++
        } else {
            $alreadyCorrect++
        }
    } else {
        if ($DryRun) {
            Write-Host ("[DRY] ADD    {0}" -f $d.Value) -ForegroundColor Green
        } else {
            try {
                Add-AllowListEntry -Jwt $jwt -CompanyId $CompanyId -Type $d.Type -Value $d.Value -Comment $Comment
                Write-Host ("  ADDED    {0}" -f $d.Value) -ForegroundColor Green
            } catch {
                Write-Host ("  ERROR    {0}: {1}" -f $d.Value, (Format-HttpError $_)) -ForegroundColor Red
                $errors++
                continue
            }
        }
        $added++
    }
}

Write-Host ''
Write-Host '--- Summary ---' -ForegroundColor Cyan
Write-Host ("added={0}, updated={1}, already_correct={2}, errors={3}" -f $added, $updated, $alreadyCorrect, $errors)
if ($DryRun) { Write-Host '(dry run: no changes were made)' -ForegroundColor Yellow }

Write-Host ''
Write-Host '--- Manual step (not exposed by the AppAPI) ---' -ForegroundColor Magenta
Write-Host 'In the IronScales web UI:'
Write-Host '  Settings -> Threat Protection -> Report Phishing Add-on (O365) -> Simulation Mail Reported'
Write-Host 'Set the text to:'
Write-Host ''
$emDash = [char]0x2014
$rsquo  = [char]0x2019
$reportedText = "Simulation only $emDash great job reporting it! Others may receive similar emails, so please don${rsquo}t warn them. Thanks!"
Write-Host ("  " + $reportedText) -ForegroundColor White
Write-Host ''
Write-Host '--- Verification ---' -ForegroundColor Magenta
Write-Host '  Settings -> Threat Protection -> Allow List           (entries with Skip All Inspections + both flags)'
Write-Host '  Settings -> Simulation & Training -> Ignore IP Range  (same backend list; entries should appear here too)'
Write-Host '  Confirm past-campaign behavior reflects the new flags.'

if ($errors -gt 0) { exit 1 } else { exit 0 }
