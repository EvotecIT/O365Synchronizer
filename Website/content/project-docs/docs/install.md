---
title: "Install O365Synchronizer"
description: "Install O365Synchronizer from the PowerShell Gallery."
layout: docs
---

Install O365Synchronizer before trying the curated Microsoft 365 contact synchronization examples.

```powershell
Install-Module -Name O365Synchronizer -Scope CurrentUser
Import-Module O365Synchronizer
```

The examples also require Microsoft Graph modules and permissions appropriate for reading users, reading org contacts, and writing personal contacts.
