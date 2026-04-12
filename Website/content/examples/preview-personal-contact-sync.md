---
title: "Preview personal contact sync"
description: "Preview synchronization of selected Microsoft 365 contacts into a mailbox."
layout: docs
---

This pattern is useful when you want to validate filters and folder targeting before writing contacts.

It is adapted from `Examples/02.PersonalContactsSynchronize.ps1`.

## Example

```powershell
Import-Module O365Synchronizer

$clientId = '<application-id>'
$tenantId = '<tenant-id>'
$clientSecret = '<client-secret>'

$credential = [pscredential]::new($clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $credential -TenantId $tenantId -NoWelcome

Sync-O365PersonalContact `
    -UserId 'pilot.user@example.com' `
    -MemberTypes 'Member', 'Contact' `
    -GuidPrefix 'O365Synchronizer' `
    -FolderName 'O365Sync' `
    -WhatIf |
    Format-Table *
```

## What this demonstrates

- previewing contact synchronization
- targeting a specific mailbox and folder
- limiting synchronized object types

## Source

- [02.PersonalContactsSynchronize.ps1](https://github.com/EvotecIT/O365Synchronizer/blob/master/Examples/02.PersonalContactsSynchronize.ps1)
