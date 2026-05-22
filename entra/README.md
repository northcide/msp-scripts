# entra/

Scripts that act against Microsoft 365 / Entra ID tenants — user and admin account provisioning, role assignment, conditional access, directory hygiene. Most call Microsoft Graph; a few may use Exchange Online or older Azure AD modules where Graph coverage is incomplete.

## Contents

| Folder | Purpose |
|---|---|
| `365-tenant-admin-setup/` | One-shot provisioning of standard admin accounts (breakglass + day-to-day) and a baseline CA policy on a new tenant. |

New work goes in its own subfolder under `entra/`. Subfolder names describe the job ("365-tenant-admin-setup", "guest-cleanup", "ca-policy-audit") rather than the cmdlet or module.
