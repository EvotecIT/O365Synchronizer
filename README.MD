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
- [ ] Synchronize Users between tenants as Contacts
- ✅ Synchronize GAL (Users & Contacts) to user mailbox
  - ✅ Add
  - ✅ Update
  - ✅ Remove
- [ ] Backup current contacts
- ✅ Remove current contacts
- ✅ Remove current "synchronized" contacts

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
    'Mailozaurr'
    'PSWriteHTML'
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

### Permissions required

Before being able to synchronize GAL to users contact list you need to create application in O365 with following permissions:

- `User.Read.All` - to read users
- `OrgContact.Read.All` - to read contacts
- `Contacts.ReadWrite` - to write contacts
- `Group.Read.All` - to read groups
- `MailboxSettings.Read` - to read mailbox settings
 
### Synchronize GAL to user mailbox

```powershell
Import-Module O365Synchronizer

$ClientID = '9e1b3'
$TenantID = 'ceb371'
$ClientSecret = 'nQF8'

# Option 1
# you need to encrypt the secret, it will only work with 2.0 of Graph Module tho
#$ClientSecretEncrypted = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
#[pscredential] $Secret = [System.Management.Automation.PSCredential]::new($ClientID, $ClientSecretEncrypted)
#Connect-MgGraph -ClientSecretCredential $Secret -TenantId $TenantID

# Option 2
$Token = Get-MgToken -ClientID $ClientID -ClientSecret $ClientSecret -TenantID $TenantID
Connect-MgGraph -AccessToken $Token

# Synchronization per user or multiple users in one
Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl', 'adam.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' | Format-Table *
```