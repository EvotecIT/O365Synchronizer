---
title: "Clear synchronized personal contacts"
description: "Preview cleanup of synchronized contacts from a mailbox folder."
layout: docs
---

This pattern is useful when you need to remove only contacts previously stamped by O365Synchronizer.

It is adapted from `Examples/01.PersonalContactsClear.ps1`.

## Example

```powershell
Import-Module O365Synchronizer

$clientId = '<application-id>'
$tenantId = '<tenant-id>'
$clientSecret = '<client-secret>'

$credential = [pscredential]::new($clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $credential -TenantId $tenantId -NoWelcome

Clear-O365PersonalContact `
    -Identity 'pilot.user@example.com' `
    -GuidPrefix 'O365Synchronizer' `
    -FolderName 'O365Sync' `
    -WhatIf
```

## What this demonstrates

- connecting with application credentials
- targeting one pilot mailbox
- previewing cleanup of synchronized contacts only

## Source

- [01.PersonalContactsClear.ps1](https://github.com/EvotecIT/O365Synchronizer/blob/master/Examples/01.PersonalContactsClear.ps1)
