# 365 Allowlisting + Report-Phishing Button

PowerShell to apply a consistent Defender for Office 365 allowlist posture to new M365 tenants — specifically the settings needed so a third-party phishing-simulation/training platform (e.g. Ironscales, KnowBe4) can deliver simulated phish, and so end users use the vendor's Outlook add-in instead of Microsoft's native **Report Phishing** button.

## What the script touches

| Setting | Portal URL | Cmdlet (under the hood) |
|---|---|---|
| Phishing Simulation advanced delivery — Domains + Sending IPs | `security.microsoft.com/advanceddelivery?viewid=PhishingSimulation` | `New-/Set-ExoPhishSimOverrideRule`, `New-/Set-PhishSimOverridePolicy` |
| Phishing Simulation Allowed Simulation URLs | `security.microsoft.com/advanceddelivery?viewid=PhishingSimulation` (same page) | `Get-/New-TenantAllowBlockListItems -ListType Url -ListSubType AdvancedDelivery -Allow -NoExpiration` |
| Connection filter policy IP allow list | `security.microsoft.com/antispam` → Default policy | `Set-HostedConnectionFilterPolicy -IPAllowList @{Add=...}` |
| Native Microsoft "Report Phishing" button *(gated on checkbox)* | `security.microsoft.com/securitysettings/userSubmission` | `Set-ReportSubmissionPolicy`, `Remove-ReportSubmissionRule` |
| Ironscales Report Phishing OWA add-in — org-wide install *(gated on checkbox)* | `admin.microsoft.com/AdminPortal/Home#/Settings/IntegratedApps` | `New-OrganizationAddIn`, `Set-OrganizationAddInAssignments -AssignToEveryone $true` (module: `O365CentralizedAddInDeployment`) |

None of the first four have a Microsoft Graph endpoint — Exchange Online PowerShell is the only programmatic path. The Ironscales add-in install uses the Centralized Deployment service (same backend as the M365 Admin Center → Integrated Apps UI).

## How it works

`Sync-AllowlistReport.ps1` reads the snapshot in `./reference/` and **merges** the values into the signed-in target tenant. Existing entries on the tenant are never removed — the script only adds what's missing. Run it once per tenant during onboarding; safe to re-run (idempotent).

The reference snapshot is checked into git. Update it by hand-editing the files when Ironscales' IP/domain/URL list changes, or replace `ironscales-owa-addin-manifest.xml` with a newer manifest from your Ironscales console. There's no Export mode in the script anymore — that was scaffolding used while building it.

## Reference files

Stored in `./reference/`. Checked into git so changes are version-controlled.

| File | Format | Contents |
|---|---|---|
| `phishsim-domains.txt` | One domain per line. Lines starting with `#` are comments. | Sending domains for the phish-sim vendor. |
| `phishsim-ipranges.txt` | One IP / range / CIDR per line. | Source IPs for the phish-sim vendor (CIDR `/24`–`/32` only; no IPv6). |
| `phishsim-urls.txt` | One URL per line (bare host or host with `/*` wildcard path). | Allowed Simulation URLs — written to the Tenant Allow/Block List with `ListSubType=AdvancedDelivery`. These ensure Safe Links / ATP doesn't rewrite or block links inside simulation emails. |
| `connection-filter-ipallowlist.txt` | One IPv4 / range / CIDR per line. | IPs that should always be classified as good by the connection filter. |
| `report-submission-policy.json` | JSON object. | The 9 toggles + `RemoveSubmissionRule` flag that together disable the native Report Phishing button. Values are fixed (all `false` / `null`) — this file exists so the Apply flow has a single source of truth and so the disable posture is explicit in the repo. |
| `ironscales-owa-addin-manifest.xml` | OWA add-in manifest XML (Office Manifest schema). | Ironscales' published Report Phishing add-in manifest. The script reads the top-level `<Id>` GUID at runtime for idempotency checks (matches `ProductId` returned by `Get-OrganizationAddIn`). Replace the file in place to upgrade to a newer manifest from Ironscales. |

Hand-editing the `.txt` files is fine — order doesn't matter, blank lines and `#` comments are ignored.

## Prerequisites

- PowerShell 7.1+
- `ExchangeOnlineManagement` module — installed automatically on first run if missing
- `O365CentralizedAddInDeployment` module — installed automatically on first run if the Ironscales install checkbox is checked
- Sign-in account: a **Global Administrator**.
  - Settings #1–4 also accept a direct member of the Exchange Online `Organization Management` or `Security Administrator` role group. Entra-only role assignments (e.g. Entra "Security Administrator") are **not** sufficient for the PhishSim cmdlets — those check Exchange RBAC, which doesn't always inherit from Entra.
  - Setting #5 (Ironscales add-in install via Centralized Deployment) **requires Global Administrator** — Exchange/Security Admin are not enough for the `O365CentralizedAddInDeployment` cmdlets.
- For Advanced Delivery (PhishSim), the target tenant needs **Defender for Office 365 Plan 1** or higher (SKU `ATP_ENTERPRISE` or any bundle that includes it). Without that license, the Advanced Delivery API returns generic server-side errors.
- For the add-in install, `(Get-OrganizationConfig).AppsForOfficeEnabled` must be `$true` on the tenant. The script checks this and SKIPs section #5 cleanly if not.

### Known Microsoft-side limitation: PhishSim cmdlets return 403

`Get-PhishSimOverridePolicy`, `Get-ExoPhishSimOverrideRule`, and their `New-*` siblings can return a generic "server side error" (HTTP 403 under verbose) even for:

- Tenant **Global Administrators** in Entra ID
- Direct members of the Exchange Online **Organization Management** role group
- Direct members of the Exchange Online **Security Administrator** role group
- Tenants with Defender for Office 365 Plan 1+ license
- Tenants with Defender XDR Unified RBAC **Not active** for Email & collaboration

In other words: this happens even when every legitimate authorization path has been satisfied. Sibling Defender cmdlets (`Get-ReportSubmissionPolicy`, `Get-AntiPhishPolicy`, `Get-EmailTenantSettings`, `Get-HostedConnectionFilterPolicy`, `Get-TenantAllowBlockListItems`) all work fine in the same session — the issue is isolated to the Advanced Delivery (PhishSim) cmdlet authorization path. This has been confirmed on multiple tenants. It appears to be a Microsoft-side bug or undocumented restriction.

**How the script handles it**: when both `Get-` and `New-` for the policy/rule return the opaque 403 pattern, the PhishSim section **SKIPs cleanly** and prints the portal URL + the exact domains/IPs you need to add manually. The other four sections (URLs, connection filter, report submission, Ironscales add-in) continue to work normally on the same run, so onboarding doesn't get blocked.

**Manual workaround**: when you see this SKIP, open `https://security.microsoft.com/advanceddelivery?viewid=PhishingSimulation` for the affected tenant and paste in the domains and sending IPs (the script's output enumerates them for you). It takes about a minute per tenant via the portal's Edit flyout.

If you want a definitive Microsoft answer, open a support ticket and include: the tenant ID, the verbose output (`POST .../adminapi/beta/.../InvokeCommand → 403 Forbidden`), and the role group membership evidence. Microsoft Support generally needs that level of detail to escalate to the right team.

## Usage

**Interactive TUI (default):**

```powershell
.\Sync-AllowlistReport.ps1
```

Two menu fields:

1. **Disable native Report Phishing and install Ironscales button** — checkbox, **default ON**. Gates settings #4 and #5 together. Uncheck for a maintenance refresh of just the allowlist (settings #1–3) without touching the user-facing Report Phishing experience.
2. **WhatIf** — dry-run toggle.

Arrow keys navigate, space toggles, Enter runs, Esc cancels. Falls back to a `Read-Host` prompt if your host doesn't support virtual terminal sequences.

**Non-interactive:**

```powershell
.\Sync-AllowlistReport.ps1 -WhatIf
.\Sync-AllowlistReport.ps1 -InstallIronscales:$false   # allowlist only
.\Sync-AllowlistReport.ps1 -SignInAs adm-breakglass-msp@<tenant>.onmicrosoft.com
```

Passing either `-WhatIf` or `-InstallIronscales` skips the TUI menu (other options use defaults). `-InstallIronscales` is a `[Nullable[bool]]` switch: omit to take the default (ON), pass `-InstallIronscales:$false` to skip the disable + install pair.

**WhatIf**: previews everything that would be added without making any writes.

## Apply behavior — merge, not replace

The Apply flow reads each list from the target tenant first, computes `missing = reference - current`, and only adds missing entries. It never calls `Remove-*` or replaces a list wholesale. So if a tenant has its own additional entries (e.g. a different vendor in the same connection filter), they survive intact.

The one exception is the **Report Submission Policy**, where every toggle from the reference JSON is set unconditionally — that's the point of that file (force the native button off). And `Remove-ReportSubmissionRule` runs if any rule exists, because keeping a submission rule alongside the disabled-button policy is contradictory.

## Notes

- The script discovers the signed-in tenant via `(Get-OrganizationConfig).Name` and shows it before any write — read it before confirming, to be sure you're acting on the right tenant.
- The session disconnects automatically on exit, including on errors. The Ironscales install step opens a **separate** auth session against the Centralized Deployment service; the browser may prompt again even after EXO sign-in succeeds (SSO usually carries it through without typing).
- A failure on one section doesn't abort the run — the remaining sections are still attempted. End-of-run summary lists each section's status (`OK` / `SKIPPED` / `FAILED`) with a verdict line, and the exit code is `2` if any section FAILED, `0` otherwise.
- The disable-Report-Phishing posture is global to the tenant. There's no per-mailbox carve-out — if a subset of users still want the native button, this script isn't the right tool.
- **Add-in propagation lag**: after a successful Ironscales install, the button appears in the M365 Admin Center → Integrated Apps view immediately, but takes **24–72 hours** to reach all users' Outlook clients (desktop, web, mobile). Don't expect to see it in your own Outlook the same day. Manual force-refresh is not possible — Microsoft caches the deployment manifest at the client.
- **Legacy `New-App -OrganizationApp` conflict**: if a tenant already has the Ironscales add-in installed via the legacy path (older deployment scripts or manual EAC steps), section #5 SKIPs with a clear message. To switch to the modern path, run `Remove-App -Identity <AppId>` first, then re-run this script. Don't run both paths in parallel — users would see two Report Phishing buttons.
