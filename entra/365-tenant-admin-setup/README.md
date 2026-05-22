# 365 Tenant Admin Account Setup

PowerShell scripts to establish and maintain a standard admin baseline on a Microsoft 365 tenant. Designed for MSP use during tenant onboarding (`New-TenantAdminAccounts.ps1`) and follow-on hygiene (`Update-BreakglassAlertEmail.ps1`).

## Scripts

| Script | Run when | Touches |
|---|---|---|
| `New-TenantAdminAccounts.ps1` | Once per tenant during onboarding | Entra ID — accounts, role assignments, one Conditional Access policy (via Microsoft Graph) |
| `Update-BreakglassAlertEmail.ps1` | When the MSP's alert-routing inbox changes, or when a tenant is handed off | Purview — `Set-ProtectionAlert` on existing breakglass-related alert policies (via Security & Compliance Center) |

The two scripts are independent — running one does not require the other. They share a common assumption that the tenant has been hardened with the breakglass-pair pattern (one MSP-held, one client-held).

---

## New-TenantAdminAccounts.ps1

Provisions a standard set of admin accounts on a new Microsoft 365 tenant via Microsoft Graph. Run once per tenant during onboarding to establish a consistent, secure admin baseline.

### What it provisions

| Account | Role(s) | MFA | Purpose |
|---|---|---|---|
| `adm-breakglass-msp` | Global Administrator | Excluded | MSP-held emergency access — stored in MSP vault |
| `adm-breakglass-client` | Global Administrator | Excluded | Client-held emergency access — stored with client |
| `adm-engineer` | Curated Tier 1 (operational) Entra ID roles — see below | Required | Day-to-day tenant engineering work |
| `adm-support` | Exchange, User, Helpdesk, SharePoint, License Admin | Required | Tier 1/2 support tasks |

A Conditional Access policy is created requiring MFA for `adm-engineer` and `adm-support`. Both breakglass accounts are explicitly excluded from all CA policies.

All accounts are created without a `usageLocation`, preventing license assignment and ensuring no mailbox, OneDrive, or Teams presence exists for these accounts.

### Prerequisites

- PowerShell 7.1 or later
- Microsoft.Graph module:
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
- An account with sufficient permissions to consent to the following Graph scopes:
  - `User.ReadWrite.All`
  - `RoleManagement.ReadWrite.Directory`
  - `Policy.ReadWrite.ConditionalAccess`
  - `Policy.Read.All`
  - `Domain.Read.All`

### Usage

**Provision accounts (standard run):**
```powershell
.\New-TenantAdminAccounts.ps1
```
A browser sign-in prompt will appear. Sign in against the target tenant. If a Microsoft Graph session is already active in the current PowerShell window it will be reused.

**Preview without making changes:**
```powershell
.\New-TenantAdminAccounts.ps1 -WhatIf
```

**Reset passwords for engineer and support accounts:**
```powershell
.\New-TenantAdminAccounts.ps1 -ResetPasswords
```
Breakglass accounts are never touched by `-ResetPasswords`.

### After running

**Breakglass (MSP):** Store credentials in the MSP secure vault. Do not share with the client.

**Breakglass (Client):** Print and hand to the client contact. Client stores in a sealed envelope in a physically separate location from the MSP copy — office safe, safety deposit box, etc. Do not store digitally.

**Engineer / Support:** Copy credentials from the console immediately and store in the MSP vault against the client record. These accounts will be prompted for MFA on first sign-in.

### Design notes

**Why two breakglass accounts?** A single breakglass creates a single point of failure — if the password is lost, corrupted, or the account is accidentally disabled, there is no recovery path. Two independently stored accounts ensure one can fail without losing emergency access. The client-held copy also ensures the client retains independent access regardless of the MSP relationship.

**Why no Global Admin for `adm-engineer`?** Global Admin is the only role that can manage other Global Admins and elevate to Azure RBAC. Keeping it off the day-to-day engineer account limits blast radius if those credentials are compromised. The breakglass accounts exist for the rare cases where GA is genuinely required.

**Why doesn't `adm-engineer` have *every* role except GA?** Several built-in roles below GA are still effective elevation paths — they let the holder grant themselves more power, weaken identity controls, or take over other admins' accounts. Standing assignment of any of these on a daily-use account turns it into "GA via the side door." Examples:

- **Privileged Role Administrator** — can grant any directory role (including GA) to anyone
- **Privileged Authentication Administrator** — can reset MFA on other admins → take over their accounts
- **Conditional Access Administrator** — can carve self-bypass exceptions in CA policies
- **Authentication Policy Administrator** — can weaken tenant-wide MFA policies
- **Application / Cloud Application Administrator** — can grant `RoleManagement.ReadWrite.Directory` to a service principal (= effective GA via SP)
- **Hybrid Identity Administrator** — controls AD Connect; can inject synthetic identities
- **Domain Name Administrator** / **External Identity Provider Administrator** — federation / DNS tricks for identity takeover

These are excluded from `adm-engineer`'s standing role grants. The recommended posture for them is **PIM-eligible (not active)** on adm-engineer in a separate post-provisioning step — requires Entra ID P2 license. Activation prompts for MFA + justification, is time-bound (typically 1–4h), and is logged. Daily ops never need these standing.

A few other roles are also excluded as either deprecated, rare, or non-user-assignable system roles (Partner Tier1/Tier2 Support, Tenant Creator, Directory Synchronization Accounts, Guest User, etc.) — see the comment block at the top of `$EngineerRoleDefinitions` in the script for the full list and rationale.

**What about other powerful roles `adm-engineer` *does* hold?** Roles like Exchange Administrator, SharePoint Administrator, and User Administrator are powerful (read all mail, all docs, manage user accounts) but aren't direct elevation paths. They're included in Tier 1 because actually *doing* an engineer's job requires them. Putting them through PIM as well is the next-level hardening move once PIM is up — a single Tier 1 PIM eligibility set covers both the operational roles in the engineer hash and the elevation roles excluded from it.

**Why no `usageLocation`?** Entra ID requires `usageLocation` before a license can be assigned. Omitting it prevents these accounts from being licensed, which eliminates the associated attack surface (no mailbox to phish, no OneDrive to exfiltrate from).

---

## Update-BreakglassAlertEmail.ps1

Re-points the notification recipients (`NotifyUser`) on Purview Protection Alert policies that watch breakglass sign-ins and CA-policy changes. Run when your MSP's alert-routing inbox changes, or when a tenant is handed off to a different MSP.

The script does **not** create the alerts themselves. They're expected to already exist in the tenant — typically created manually in the Purview portal (Security & Compliance Center → Alerts → Alert policies) as part of tenant hardening, after the accounts are provisioned. The script matches policies by name pattern:

- `Breakglass Sign-In - <upn>` — one per breakglass account
- `CA Policy Add/Update/Delete [<tenant>]`

If no policies match those patterns, the script lists any fuzzy near-matches (anything containing "breakglass" or starting with "CA Policy") and exits without making changes — so a renamed alert can't silently get missed.

### Prerequisites

- PowerShell 7.1 or later
- An E5 or E3 + Threat Intelligence subscription on the target tenant (Protection Alert policies are gated on these SKUs)
- `ExchangeOnlineManagement` module — installed automatically on first run if missing
- Sign-in account with **Global Admin** or **Compliance Admin** rights against the Security & Compliance Center

### Usage

**Interactive TUI (default):**
```powershell
.\Update-BreakglassAlertEmail.ps1
```
A two-field menu: notification emails (space- or comma-separated) and a `WhatIf` toggle. Falls back to a `Read-Host` prompt if the host doesn't support virtual terminal sequences.

**Non-interactive:**
```powershell
.\Update-BreakglassAlertEmail.ps1 -NewEmails alerts@example.com
.\Update-BreakglassAlertEmail.ps1 -NewEmails 'a@x.com','b@x.com' -WhatIf
```

### Notes

- The `$DefaultAlertEmails` value at the top of the script (currently `alerts@example.com`) seeds the TUI's default field — edit it to your MSP's real inbox before first interactive run, or always pass `-NewEmails`.
- `-WhatIf` previews the policy set without calling `Set-ProtectionAlert`.
- A failure on one policy does not abort the run — the rest are still attempted, and the final summary lists successes vs. failures.
- The session disconnects automatically on exit, including on errors.
