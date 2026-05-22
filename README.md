# MSP-Scripts

PowerShell scripts used in day-to-day MSP work. Organized by execution platform.

## Layout

```
msp-scripts/
├── entra/         # Microsoft 365 / Entra ID tenant administration scripts
├── ironscales/    # Scripts that drive the IronScales email-security platform
├── ninjaone/      # Scripts deployed and run via the NinjaOne RMM
└── standalone/    # Scripts run interactively or outside an RMM
```

New platforms (e.g. `huntress/`, `m365/`) get their own top-level folder as work expands. Within a platform folder, related scripts/data live in their own subfolder (e.g. `ironscales/ironscales-huntress-allowlisting/`).

## Scripts

### entra/

| Script | Purpose | Setup |
|---|---|---|
| `365-tenant-admin-setup/New-TenantAdminAccounts.ps1` | Provisions a standard set of admin accounts (two breakglass, `adm-engineer`, `adm-support`) on a new Microsoft 365 tenant via Microsoft Graph, plus a CA policy requiring MFA. `-WhatIf` previews; `-ResetPasswords` rotates engineer/support creds without touching breakglass. | PowerShell 7.1+, `Microsoft.Graph` module. See `365-tenant-admin-setup/README.md` for required Graph scopes and post-run credential-storage guidance. |

### ironscales/

`ironscales-management-api.md` is the IronScales AppAPI reference, kept alongside platform scripts.

| Script | Purpose | Setup |
|---|---|---|
| `ironscales-huntress-allowlisting/Sync-IronscalesAllowlist.ps1` | Idempotently allowlists Curricula (Huntress) phishing-simulation domains and IPs in an IronScales tenant. Supports `-DryRun`. | Reads `domains.txt` and `ips.txt` from its own folder. Company ID and Company Token are entered interactively or via `-CompanyId` — never read from or written to disk. |

### ninjaone/

| Script | Purpose | NinjaOne setup |
|---|---|---|
| `Get-WarrantyStatus.ps1` | Looks up device warranty via the [PSWarranty](https://www.powershellgallery.com/packages/PSWarranty) module and writes the end date to a custom field. | Text custom field named `WarrantyStatus`. Set vendor API keys (Dell, Lenovo, etc.) once via `Set-WarrantyAPIKeys` — the call is left commented at the top of the script. |
| `Get-WifiReport.ps1` | Generates a wireless LAN report and writes it to a WYSIWYG custom field. | WYSIWYG custom field; pass its name via `-CustomField <name>` or set the NinjaOne script variable `wysiwygCustomFieldName`. |

### standalone/

| Script | Purpose | Notes |
|---|---|---|
| `Install-GoogleEarthPro.ps1` | Silent install of Google Earth Pro (64-bit). | Downloads installer to `C:\temp` and logs to `C:\temp\PSInstallLog.txt`. |
| `Invoke-NetworkTest.ps1` | WPF GUI for ad-hoc network diagnostics (ping, gateway, public IP, Wi-Fi). | Run interactively on the affected machine. |

## Conventions

- **Filenames** follow PowerShell `Verb-Noun.ps1` (PascalCase, no spaces).
- **Block comments** use `<# ... #>`, never `/* ... */`.
- **NinjaOne custom-field writes** use `Ninja-Property-Set` (or `Set-NinjaProperty` helper) and the field is documented in the table above.
