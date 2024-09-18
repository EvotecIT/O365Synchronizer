<p align="center">
  <a href="https://www.powershellgallery.com/packages/O365Synchronizer"><img src="https://img.shields.io/powershellgallery/v/O365Synchronizer.svg"></a>
  <a href="https://www.powershellgallery.com/packages/O365Synchronizer"><img src="https://img.shields.io/powershellgallery/vpre/O365Synchronizer.svg?label=powershell%20gallery%20preview&colorB=yellow"></a>
  <a href="https://github.com/EvotecIT/O365Synchronizer"><img src="https://img.shields.io/github/license/EvotecIT/O365Synchronizer.svg"></a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/O365Synchronizer"><img src="https://img.shields.io/powershellgallery/p/O365Synchronizer.svg"></a>
  <a href="https://github.com/EvotecIT/O365Synchronizer"><img src="https://img.shields.io/github/languages/top/evotecit/O365Synchronizer.svg"></a>
  <a href="https://github.com/EvotecIT/O365Synchronizer"><img src="https://img.shields.io/github/languages/code-size/evotecit/O365Synchronizer.svg"></a>
  <a href="https://www.powershellgallery.com/packages/O365Synchronizer"><img src="https://img.shields.io/powershellgallery/dt/O365Synchronizer.svg"></a>
</p>

<p align="center">
  <a href="https://twitter.com/PrzemyslawKlys"><img src="https://img.shields.io/twitter/follow/PrzemyslawKlys.svg?label=Twitter%20%40PrzemyslawKlys&style=social"></a>
  <a href="https://evotec.xyz/hub"><img src="https://img.shields.io/badge/Blog-evotec.xyz-2A6496.svg"></a>
  <a href="https://www.linkedin.com/in/pklys"><img src="https://img.shields.io/badge/LinkedIn-pklys-0077B5.svg?logo=LinkedIn"></a>
</p>

**O365Synchronizer** is a PowerShell module that allows you to synchronize users/contacts to user mailboxes contact list. It can also be used to synchronize users between tenants as contacts or guests.

## Features & ToDo

- [ ] Synchronize Users between tenants as Guests
- ✅ Synchronize Users between tenants as Contacts (organization contacts)
  - ✅ Add
  - ✅ Update
  - ✅ Remove
- ✅ Synchronize GAL (Users & Contacts) to user mailbox (personal contacts)
  - ✅ Add
  - ✅ Update
  - ✅ Remove
- [ ] Backup current contacts
- ✅ Remove current personal contacts
- ✅ Remove current personal "synchronized" contacts

## Installing/Updating

### For using as a module

Installation doesn't require administrative rights. You can install it using following:

```powershell
Install-Module O365Synchronizer
```

But if you don't have administrative rights on your machine:

```powershell
Install-Module O365Synchronizer -Scope CurrentUser
```

To update

```powershell
Update-Module -Name O365Synchronizer
```

That's it. Whenever there's a new version you simply run the command and you can enjoy it.
Remember, that you may need to close, reopen the PowerShell session if you have already used the module before updating it.
**The important thing** is if something works for you on production, keep using it till you test the new version on a test computer.
I do changes that may not be big, but big enough that auto-update will break your code.
For example, small rename to a parameter and your code stops working! Be responsible!

### For development purposes

If you want to contribute to the module, you can clone the repository and use it as a module, but you will need those to be installed:

```powershell
$Modules = @(
    'PSSharedGoods'
    #'Mailozaurr'
    #'PSWriteHTML'
    'PSWriteColor'
)
$ModulesGraph = @(
    'Microsoft.Graph.Identity.SignIns'
    'Microsoft.Graph.Identity.DirectoryManagement'
    'Microsoft.Graph.Users'
    'Microsoft.Graph.PersonalContacts'
    'Microsoft.Graph.Authentication'
)
foreach ($Module in $Modules) {
    Install-Module -Name $Module -Force -Scope CurrentUser -Verbose
}

# Graph modules, which can be used with prerlease versions
foreach ($Module in $ModulesGraph) {
    Install-Module -Name $Module -Force -Scope CurrentUser -AllowPrerelease -Verbose
}
```

## Usage

### Synchronize GAL to user mailbox

#### Permissions required

Before being able to synchronize GAL to users contact list you need to create application in O365 with following permissions:

- `User.Read.All` - to read users
- `OrgContact.Read.All` - to read contacts
- `Contacts.ReadWrite` - to write contacts

#### Example

```powershell
Import-Module O365Synchronizer

$ClientID = '9e1b3'
$TenantID = 'ceb371'
$ClientSecret = 'nQF8'

$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

# Synchronization per user or multiple users in one
Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl', 'adam.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' | Format-Table *
```

### Synchronize users between tenants

#### Permissions required

Source tenant:
- `User.Read.All` - to read users

Target tenant:
- `Exchange.ManageAsApp` - to read/write contacts in Exchange (remember to add application to `Exchange Recipient Administrator` role)

#### Example

To synchronize users/contacts from Source tenant to Destination tenant you can do it in following way:

```powershell
# Source Tenant
$ClientID = '9e1b3c36'
$TenantID = 'ceb371f6'
$ClientSecret = 'NDE'

$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

# do the filtering of any kind on UsersToSync to get the users you want to synchronize
$UsersToSync = Get-MgUser | Select-Object -First 10

# Destination tenant - you need to create application with permissions to read/write contacts in Exchange
$ClientID = 'edc4302e'
Connect-ExchangeOnline -AppId $ClientID -CertificateThumbprint '2E' -Organization 'xxxxx.onmicrosoft.com'
Sync-O365Contact -SourceObjects $UsersToSync -Domains 'evotec.pl','gmail.com' -Verbose -WhatIf
```

You can revert the order and set it up to synchronize from Destination tenant to Source tenant to have a two-way synchronization.

#### Filtering & Folder support

```powershell
# synchronize contacts for 1 user of two types (Member, Contact) using GUID prefix and filtering by company name
# this will only synchronize contacts that have CompanyName starting with 'Evotec' or 'Ziomek'
# this will also require contacts to be in a group by 'e7772951-4b0e-4f10-8f38-eae9b8f55962'
# this will also create a folder 'O365Sync' in user's personal contacts and put synchronized contacts there
# this will also return the results in a table
Sync-O365PersonalContact -UserId 'test@evotec.pl' -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' -PassThru {
    Sync-O365PersonalContactFilter -Type Include -Property 'CompanyName' -Value 'Evotec*','Ziomek*' -Operator 'like'
    Sync-O365PersonalContactFilterGroup -Type Include -GroupID 'e7772951-4b0e-4f10-8f38-eae9b8f55962'
} -FolderName 'O365Sync' | Format-Table
```

### Clearing personal contacts

```powershell
# this is useful to clear current user contacts (if you have some)
# this will only delete synchronized ones (based on FileAs property that has to convert to GUID)
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -WhatIf

# this is useful to clear current user contacts (if you have some)
# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix)
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -WhatIf

# this will delete all contacts
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -All -WhatIf

# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix) from specific folder
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -FolderName 'O365' -WhatIf

# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix) from specific folder, including the folder
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -FolderName 'O365Sync' -FolderRemove -WhatIf
```