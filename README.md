# MSP-Scripts

PowerShell scripts used in day-to-day MSP work. Organized by execution platform.

## Layout

```
msp-scripts/
├── entra/                       # Microsoft 365 / Entra ID tenant administration scripts
├── ironscales/                  # Scripts that drive the IronScales email-security platform
├── local-admin-group-cleansing/ # Locks down local Administrators membership (NinjaOne-deployed)
├── ninjaone/                    # Scripts deployed and run via the NinjaOne RMM
└── standalone/                  # Scripts run interactively or outside an RMM
```

New platforms (e.g. `huntress/`, `m365/`) get their own top-level folder as work expands. Within a platform folder, related scripts/data live in their own subfolder (e.g. `ironscales/ironscales-huntress-allowlisting/`).

## Scripts

### entra/

| Script | Purpose | Setup |
|---|---|---|
| `365-tenant-admin-setup/New-TenantAdminAccounts.ps1` | Interactive menu to manage admin accounts on a Microsoft 365 tenant via Microsoft Graph: provision the standard set (two breakglass, `adm-engineer`, `adm-support`) with an MFA CA policy, create a subset, create a custom-named account from a role template, or reset passwords by typed UPN (breakglass excluded). `-WhatIf` previews; `-ResetPasswords` bypasses the menu to rotate engineer/support creds without touching breakglass. | PowerShell 7.1+, `Microsoft.Graph` module. See `365-tenant-admin-setup/README.md` for required Graph scopes and post-run credential-storage guidance. |
| `365-tenant-admin-setup/Update-BreakglassAlertEmail.ps1` | Updates the notification recipients on existing Purview Protection Alert policies for breakglass sign-ins and CA-policy changes. Used when the MSP's alert-routing inbox changes or a tenant is handed off. TUI menu by default; `-NewEmails` and `-WhatIf` for non-interactive use. | PowerShell 7.1+, `ExchangeOnlineManagement` module (auto-installed). Requires E5 or E3 + Threat Intelligence on the target tenant. Does not create the alerts — they must already exist. |

### ironscales/

`ironscales-management-api.md` is the IronScales AppAPI reference, kept alongside platform scripts.

| Script | Purpose | Setup |
|---|---|---|
| `ironscales-huntress-allowlisting/Sync-IronscalesAllowlist.ps1` | Idempotently allowlists Curricula (Huntress) phishing-simulation domains and IPs in an IronScales tenant. Supports `-DryRun`. | Reads `domains.txt` and `ips.txt` from its own folder. Company ID and APP API Token are entered interactively or via `-CompanyId` — never read from or written to disk. Both values come from IronScales: customer context → settings cog (top right). |

### ninjaone/

| Script | Purpose | NinjaOne setup |
|---|---|---|
| `Get-WarrantyStatus.ps1` | Looks up device warranty via the [PSWarranty](https://www.powershellgallery.com/packages/PSWarranty) module and writes the end date to a custom field. | Text custom field named `WarrantyStatus`. Set vendor API keys (Dell, Lenovo, etc.) once via `Set-WarrantyAPIKeys` — the call is left commented at the top of the script. |
| `Get-WifiReport.ps1` | Generates a wireless LAN report and writes it to a WYSIWYG custom field. | WYSIWYG custom field; pass its name via `-CustomField <name>` or set the NinjaOne script variable `wysiwygCustomFieldName`. |

### local-admin-group-cleansing/

| Script | Purpose | NinjaOne setup |
|---|---|---|
| `Set-LocalAdminMembers.ps1` | Enforces local Administrators membership on Win10/11 workstations: keeps only Domain Admins (if domain-joined) + a managed local account from `LocalAdminUsername`/`LocalAdminPassword`, creating/enabling/resetting that account as needed. Preserves the built-in Administrator (`-500`) and Entra principals (`S-1-12-1-*`); removes everything else. `-DryRun` previews. Aborts before any change if creds are missing. | Custom fields `LocalAdminUsername` (Text) and `LocalAdminPassword` (Secure), both with Script read. Run as SYSTEM. See `local-admin-group-cleansing/README.md`. |

### standalone/

| Script | Purpose | Notes |
|---|---|---|
| `Install-GoogleEarthPro.ps1` | Silent install of Google Earth Pro (64-bit). | Downloads installer to `C:\temp` and logs to `C:\temp\PSInstallLog.txt`. |
| `Invoke-NetworkTest.ps1` | WPF GUI for ad-hoc network diagnostics (ping, gateway, public IP, Wi-Fi). | Run interactively on the affected machine. |

## Conventions

- **Filenames** follow PowerShell `Verb-Noun.ps1` (PascalCase, no spaces).
- **Block comments** use `<# ... #>`, never `/* ... */`.
- **NinjaOne custom-field writes** use `Ninja-Property-Set` (or `Set-NinjaProperty` helper) and the field is documented in the table above.
