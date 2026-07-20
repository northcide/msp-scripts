# entra/

Scripts that act against Microsoft 365 / Entra ID tenants — user and admin account provisioning, role assignment, conditional access, directory hygiene. Most call Microsoft Graph; a few may use Exchange Online or older Azure AD modules where Graph coverage is incomplete.

## Contents

| Folder | Purpose |
|---|---|
| `365-tenant-admin-setup/` | Interactive menu to provision standard admin accounts (breakglass + day-to-day), create custom accounts from a role template, reset passwords, and maintain a baseline CA policy on a tenant. |
| `365-allowlisting-report-phishing-button/` | Sync Defender for Office 365 allowlist settings (PhishSim advanced delivery, connection filter IPs, native Report Phishing toggle) from a reference tenant to new tenants. |

New work goes in its own subfolder under `entra/`. Subfolder names describe the job ("365-tenant-admin-setup", "guest-cleanup", "ca-policy-audit") rather than the cmdlet or module.
