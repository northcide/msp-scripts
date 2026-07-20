# IronScales Allowlisting for Curricula (Huntress) Phishing Simulations

`Sync-IronscalesAllowlist.ps1` ensures the Curricula / Huntress phishing-simulation sending domains and IPs are present in an IronScales tenant's Allow List with the right flags so the sims aren't quarantined or rewritten.

This is the IronScales-side counterpart to `entra/365-allowlisting-report-phishing-button/` (which does the Microsoft 365 / Defender side). Run both per tenant during onboarding.

## What the script does

For every entry in `domains.txt` and `ips.txt`, the script ensures a corresponding row exists in IronScales at **Settings → Threat Protection → Allow List** with:

| Flag | Value | UI label |
|---|---|---|
| `scope` | `1` | Skip All Inspections |
| `ignore_auth` | `true` | Ignore SPF/DKIM/DMARC + internal/external auth |
| `external_campaigns` | `true` | Show response message for external campaigns |

The same backend list also drives **Settings → Simulation & Training → Ignore IP Range** — entries written here show up in both places.

Behavior is idempotent:

- Missing entries → `POST` (added)
- Existing entries with wrong flags → `PUT` (updated in place)
- Existing entries with correct flags → left alone

## Not handled by the script (manual step)

The **Simulation Mail Reported** text at *Settings → Threat Protection → Report Phishing Add-on (O365) → Simulation Mail Reported* is not exposed by the IronScales AppAPI. At the end of every run the script prints the exact UI path and the text to paste:

> Simulation only — great job reporting it! Others may receive similar emails, so please don't warn them. Thanks!

## Files

| File | Format | Contents |
|---|---|---|
| `domains.txt` | One domain per line. Blank lines and lines starting with `#` are ignored. | Curricula sending domains (`mycurricula.com`, `*notice*.{com,org}`, etc.). |
| `ips.txt` | One IP or CIDR per line. Same comment/blank rules. | Curricula sending IPs. |
| `Sync-IronscalesAllowlist.ps1` | The script. | — |

Update `domains.txt` / `ips.txt` in place when Curricula publishes a new list. Order doesn't matter.

## Prerequisites

- PowerShell 5.1+ (works on Windows PowerShell and PowerShell 7).
- An IronScales **Company ID** and **APP API Token** for the target tenant.
- Network egress to `https://appapi.ironscales.com`.

**Where to find the Company ID and APP API Token:**

1. Log into IronScales and switch into the customer context.
2. Click the settings cog in the top right.
3. The **Company ID** and **APP API Token** are both listed on that page.

The APP API Token is entered interactively as a `SecureString` and held in memory only — it is never written to disk, logged, or persisted to the PowerShell history. The script exchanges it for a short-lived JWT (`company.view`, `company.edit` scopes) and uses that for the rest of the run.

## Usage

**Interactive (default):**

```powershell
.\Sync-IronscalesAllowlist.ps1
```

You'll be prompted for:

1. **Company ID** — the prompt re-prints the navigation steps (settings cog → Company ID).
2. **Run mode** — `L` (LIVE, applies changes) or `D` (DRY RUN, preview only — default if you just press Enter).
3. **APP API Token** (masked) — the prompt re-prints the navigation steps (settings cog → APP API Token).

**Non-interactive:**

```powershell
# Dry run against a specific tenant
.\Sync-IronscalesAllowlist.ps1 -CompanyId 12345 -DryRun

# Live run against a specific tenant
.\Sync-IronscalesAllowlist.ps1 -CompanyId 12345 -DryRun:$false

# Point at alternate input files
.\Sync-IronscalesAllowlist.ps1 -CompanyId 12345 -DomainsFile .\custom-domains.txt -IpsFile .\custom-ips.txt
```

Passing `-DryRun` (in either form) skips the mode prompt. The APP API Token prompt is always interactive — there's no parameter for it, on purpose.

**Parameters:**

| Parameter | Default | Notes |
|---|---|---|
| `-CompanyId` | *prompt* | IronScales numeric company ID. |
| `-DomainsFile` | `.\domains.txt` | Path to the domains list. |
| `-IpsFile` | `.\ips.txt` | Path to the IPs/CIDRs list. |
| `-Comment` | `Curricula simulation allowlist` | Written on newly created entries (not on updates). |
| `-DryRun` | *prompt* | Switch. Preview without writing. |

## Output

Per-entry lines tagged `ADDED`, `UPDATED`, `[DRY] ADD`, `[DRY] UPDATE`, or nothing (already correct), then a summary:

```
--- Summary ---
added=4, updated=0, already_correct=20, errors=0
```

Exit code is `1` if any entry hit an error, `0` otherwise. Errors on individual entries don't abort the run — the remaining entries are still processed.

## Verification

After a live run, check in the IronScales UI:

- **Settings → Threat Protection → Allow List** — every desired entry present, all three flags set as in the table above.
- **Settings → Simulation & Training → Ignore IP Range** — IPs from `ips.txt` show up here too (same backend list).
- Past campaigns reflect the new flags (IronScales recomputes campaign decisions when the allow list changes).

## Notes

- **One tenant per run.** The Company Token is per-tenant; to onboard multiple tenants, run the script once per tenant.
- **Paging.** The script pulls the existing allow list 500 entries per page until it's exhausted, so tenants with very large lists are handled correctly.
- **Auth fallback.** The token exchange tries the raw `Authorization: <key>` header first and falls back to `Authorization: Bearer <key>` if the first form returns 401/403 — IronScales has historically accepted both depending on the tenant region.
- See `../ironscales-management-api.md` for the AppAPI reference these calls are built against.
