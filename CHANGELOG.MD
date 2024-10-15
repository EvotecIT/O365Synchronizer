## Changelog

### 1.0.3 - 2024.10.15
- Fixes problem with synchronizing proper contacts when using folders

### 1.0.2 - 2024.09.28
- Fixes bug when not using folder for synchronization it would prompt for contact folder id

### 1.0.1 - 2024.09.27
- Fixes too small amount of contacts gathered when using folders

### 1.0.0 - 2024.09.18
- Added `Sync-O365PersonalContactFilter` to allow filtering of users to synchronize by properties
- Added `Sync-O365PersonalContactFilterGroup` to allow filtering of users to synchronize by group membership (ID only)
- Allow synchronizing of contacts to personal contacts in Outlook to specific Folder (only 1 level deep)

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

- Improved `Clear-O365PersonalContact` to allow clearing of contacts in specific Folder, including deleting the folder itself

```powershell
# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix) from specific folder
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -FolderName 'O365' -WhatIf

# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix) from specific folder, including the folder
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -FolderName 'O365Sync' -FolderRemove -WhatIf
```



### 0.0.3 - 2023.09.25
- Improved logging
- Added more options to `Sync-O365Contact`

### 0.0.2 - 2023.09.25
- Added support for synchronizing users/objects to Exchange contacts `Sync-O365Contact` essentially allowing tenant to tenant synchronization for GAL purposes

### 0.0.1 - 2023.05.30
- Intial release
- Provides synchronization of users to personal contacts in Outlook `Sync-O365PersonalContact`
- Provides a way to clear all personal contacts in Outlook `Clear-O365PersonalContact`