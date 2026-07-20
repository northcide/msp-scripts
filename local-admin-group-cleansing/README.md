# Local Administrators Group Cleansing

Enforces a known, minimal membership of the local **Administrators** group on
Windows 10/11 **workstations** and guarantees a managed break-glass local admin
whose credentials are stored in NinjaRMM. Deploy from NinjaRMM (run as SYSTEM).

## Scripts

| Script | Run when | Touches |
|---|---|---|
| `Set-LocalAdminMembers.ps1` | On onboarding and on a recurring schedule, to keep local admin rights locked down. | Local Administrators group membership; the managed local user account. |

## What the script does

After it runs, the local Administrators group contains **only**:

| Member | Behavior |
|---|---|
| **Domain Admins** (of the joined AD domain) | Added if the machine is domain-joined and not already present. Skipped on non-domain machines. |
| **Managed local account** (`LocalAdminUsername`) | Created if missing; if present, **enabled** and its **password reset** to `LocalAdminPassword`. Both values come from the device's organization Documentation. Password set to never expire (rotated centrally via Ninja). |

The following are **preserved** and never removed (by design):

| Member | Why |
|---|---|
| Built-in Administrator (SID ends `-500`) | Recovery safety net. Left exactly as found — not enabled, not modified. |
| Entra / Azure AD principals (SID starts `S-1-12-1-`) | Avoids locking out Global Admins / Azure AD Joined Device Local Administrators on Entra- or Hybrid-joined devices. |
| **Domain Admins / Enterprise Admins of any domain** (SID `S-1-5-21-…-512` / `…-519`) | Preserved by SID pattern, so they're never stripped even when the box can't be detected as domain-joined or the domain SID can't be resolved (e.g. transient DC issues). Adding the joined domain's Domain Admins when *missing* still requires successful domain detection. |
| Anything listed in `ignoreLocalGroups` | Optional allow-list (users **or** groups, local **or** domain). Preserved only if already present — never added. Matched by SID and by name. |

**Everything else** — stray local users, other domain users/groups, legacy MSP
accounts, and orphaned/unresolvable SIDs — is removed.

## Safety

- If `LocalAdminUsername` or `LocalAdminPassword` is empty/unreadable, the script
  **aborts before making any change** — a machine can never be stripped of admins
  without a guaranteed replacement.
- Refuses to run on Server SKUs (workstation-only).
- All identity matching is done by **SID**, so it is language-independent
  (works on non-English Windows where "Administrators"/"Domain Admins" are localized).

## Prerequisites

- Windows 10 or 11 workstation. Runs under stock **Windows PowerShell 5.1**
  (no PowerShell 7, no RSAT).
- Must run **elevated** — SYSTEM when deployed via NinjaRMM.
- NinjaRMM **Documentation**: a single-page item holding the credentials,
  resolved per organization. Default: `LocalAdminAccount` (the script reads it
  via both the `-Single` and 3-arg forms, so the same name serves as template
  and document). Override with `-DocTemplate` / `-DocName` if yours differs.

  | Field (identifier) | Type | Notes |
  |---|---|---|
  | `localAdminUsername` | Text | e.g. `KishmishAdmin`. Field *identifiers* are camelCase; the label-cased name is tried as a fallback. |
  | `localAdminPassword` | **Text** | Must **not** be a secure/encrypted attribute — secure documentation fields are *write-only* and cannot be read back by the CLI, so the script could never see the password. Stored as readable text means anyone with Documentation read access to that client can see it. |
  | `ignoreLocalGroups` | Text (optional) | Comma-delimited principals to keep if already in Administrators (users or groups, local or domain). Bare name (e.g. `Local Admin`) matches the member's leaf; `DOMAIN\Name` must match in full. Preserved only — never added. |

  > **If a field reads empty / "Unable to find the specified field" but it
  > clearly exists, it's a permissions problem** — the role the automation runs
  > as needs **read** access to that Documentation Custom Field. NinjaOne reports
  > a missing read permission as a not-found error, not access-denied. (Per-field
  > permissions can differ, so a newly added field may lack the access the
  > existing fields already have.)

  The technician/role the automation runs as needs **read** permission on
  Documentation custom fields, or `Ninja-Property-Docs-Get` returns empty and
  the script aborts.

## Usage

Normal NinjaRMM run (reads both values from the org's Documentation document):

```powershell
.\Set-LocalAdminMembers.ps1
```

Preview on a test machine without changing anything (override fields locally):

```powershell
.\Set-LocalAdminMembers.ps1 -DryRun -LocalAdminUsername svc-localadmin -LocalAdminPassword 'P@ssw0rd!'
```

`-WhatIf` behaves the same as `-DryRun`.

| Parameter | Purpose |
|---|---|
| `-LocalAdminUsername` | Override the managed account name (else read from Documentation). |
| `-LocalAdminPassword` | Override the managed account password (else read from Documentation). |
| `-DocTemplate` | Documentation template name (default `Apps & Services`). |
| `-DocName` | Documentation document name (default `LocalAdminAccount`). |
| `-DryRun` | Report-only; lists every add/remove that would happen and makes no changes. |

## Output / exit codes

Console output is prefixed (`[OK]` / `[!!]` / `[XX]` / `[..]`) and shows, per
member, whether it is kept (with the reason), added, or removed. It ends with a
**Resulting Administrators membership** list — the actual group contents on a
live run (re-read after changes), or the projected contents on `-DryRun`.

| Exit code | Meaning |
|---|---|
| `0` | Success (or preview completed). |
| `1` | Aborted (missing creds / Server SKU) or one or more removals failed. |

## Verification

1. **Preview** on a domain-joined and an Entra-joined test machine — confirm the
   planned adds/removes are correct and that `-500` / `S-1-12-1-*` members are kept.
2. **Live, account missing** — confirm the account is created, enabled, in the
   group, password never expires.
3. **Live, account exists/disabled** — confirm it's enabled and the password is
   reset; re-run is idempotent (no further changes).
4. **Blank password field** — confirm the script aborts with no removals.
