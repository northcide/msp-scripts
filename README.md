# 365 Tenant Admin Account Setup

PowerShell script to provision a standard set of admin accounts on a new Microsoft 365 tenant via Microsoft Graph. Designed for MSP use — run it once per tenant during onboarding to establish a consistent, secure admin baseline.

## What it provisions

| Account | Role(s) | MFA | Purpose |
|---|---|---|---|
| `adm-breakglass-msp` | Global Administrator | Excluded | MSP-held emergency access — stored in MSP vault |
| `adm-breakglass-client` | Global Administrator | Excluded | Client-held emergency access — stored with client |
| `adm-engineer` | All built-in Entra ID roles except Global Admin | Required | Day-to-day tenant engineering work |
| `adm-support` | Exchange, User, Helpdesk, SharePoint, License Admin | Required | Tier 1/2 support tasks |

A Conditional Access policy is created requiring MFA for `adm-engineer` and `adm-support`. Both breakglass accounts are explicitly excluded from all CA policies.

All accounts are created without a `usageLocation`, preventing license assignment and ensuring no mailbox, OneDrive, or Teams presence exists for these accounts.

## Prerequisites

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

## Usage

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

## After running

**Breakglass (MSP):** Store credentials in the MSP secure vault. Do not share with the client.

**Breakglass (Client):** Print and hand to the client contact. Client stores in a sealed envelope in a physically separate location from the MSP copy — office safe, safety deposit box, etc. Do not store digitally.

**Engineer / Support:** Copy credentials from the console immediately and store in the MSP vault against the client record. These accounts will be prompted for MFA on first sign-in.

## Design notes

**Why two breakglass accounts?** A single breakglass creates a single point of failure — if the password is lost, corrupted, or the account is accidentally disabled, there is no recovery path. Two independently stored accounts ensure one can fail without losing emergency access. The client-held copy also ensures the client retains independent access regardless of the MSP relationship.

**Why no Global Admin for `adm-engineer`?** Global Admin is the only role that can manage other Global Admins and elevate to Azure RBAC. Keeping it off the day-to-day engineer account limits blast radius if those credentials are compromised. The breakglass accounts exist for the rare cases where GA is genuinely required.

**Why no `usageLocation`?** Entra ID requires `usageLocation` before a license can be assigned. Omitting it prevents these accounts from being licensed, which eliminates the associated attack surface (no mailbox to phish, no OneDrive to exfiltrate from).
