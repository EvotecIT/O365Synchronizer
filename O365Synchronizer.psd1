@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2023 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'This module allows to synchronize users to/from Office 365.'
    FunctionsToExport    = @('Clear-O365PersonalContact', 'Sync-O365Contact', 'Sync-O365PersonalContact')
    GUID                 = '81e907a0-a475-4d6a-a80d-20e9f08ad6b7'
    ModuleVersion        = '0.0.2'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            IconUri    = 'https://evotec.xyz/wp-content/uploads/2023/01/O365Synchronizer.png'
            ProjectUri = 'https://github.com/EvotecIT/O365Synchronizer'
            Tags       = @('windows', 'o365', 'synchronize', 'gal', 'contacts', 'office365', 'guests', 'graph')
        }
    }
    RequiredModules      = @(@{
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
            ModuleName    = 'PSSharedGoods'
            ModuleVersion = '0.0.266'
        }, @{
            Guid          = '2b0ea9f1-3ff1-4300-b939-106d5da608fa'
            ModuleName    = 'Mailozaurr'
            ModuleVersion = '1.1.0'
        }, @{
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
            ModuleName    = 'PSWriteHTML'
            ModuleVersion = '1.10.0'
        }, @{
            Guid          = '0b0ba5c5-ec85-4c2b-a718-874e55a8bc3f'
            ModuleName    = 'PSWriteColor'
            ModuleVersion = '1.0.1'
        }, @{
            Guid          = '60f889fa-f873-43ad-b7d3-b7fc1273a44f'
            ModuleName    = 'Microsoft.Graph.Identity.SignIns'
            ModuleVersion = '2.3.0'
        }, @{
            Guid          = 'c767240d-585c-42cb-bb2f-6e76e6d639d4'
            ModuleName    = 'Microsoft.Graph.Identity.DirectoryManagement'
            ModuleVersion = '2.3.0'
        }, @{
            Guid          = '71150504-37a3-48c6-82c7-7a00a12168db'
            ModuleName    = 'Microsoft.Graph.Users'
            ModuleVersion = '2.3.0'
        }, @{
            Guid          = 'a53e24d0-43dd-43ec-950e-7ac40ea986fc'
            ModuleName    = 'Microsoft.Graph.PersonalContacts'
            ModuleVersion = '2.3.0'
        })
    RootModule           = 'O365Synchronizer.psm1'
}