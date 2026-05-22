# MSP-Scripts

PowerShell scripts used in day-to-day MSP work. Organized by execution platform.

## Layout

```
msp-scripts/
├── ninjaone/      # Scripts deployed and run via the NinjaOne RMM
└── standalone/    # Scripts run interactively or outside an RMM
```

New platforms (e.g. `ironscales/`, `huntress/`, `m365/`) get their own top-level folder as work expands.

## Scripts

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
