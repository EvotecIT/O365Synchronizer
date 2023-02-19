@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2023 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'This module allows to synchronize users to/from Office 365.'
    FunctionsToExport    = @('Clear-O365PersonalContact', 'Set-O365Credentials', 'Sync-O365Guest', 'Sync-O365PersonalContact')
    GUID                 = '81e907a0-a475-4d6a-a80d-20e9f08ad6b7'
    ModuleVersion        = '0.0.1'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags       = 'windows'
            ProjectUri = 'https://github.com/EvotecIT/O365Synchronizer'
            IconUri    = 'https://evotec.xyz/wp-content/uploads/2023/01/O365Synchronizer.png'
        }
    }
    RequiredModules      = @(@{
            ModuleVersion = '0.0.258'
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        }, @{
            ModuleVersion = '1.0.0'
            ModuleName    = 'Mailozaurr'
            Guid          = '2b0ea9f1-3ff1-4300-b939-106d5da608fa'
        }, @{
            ModuleVersion = '0.0.183'
            ModuleName    = 'PSWriteHTML'
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
        }, @{
            ModuleVersion = '0.87.3'
            ModuleName    = 'PSWriteColor'
            Guid          = '0b0ba5c5-ec85-4c2b-a718-874e55a8bc3f'
        }, @{
            ModuleVersion = '1.20.0'
            ModuleName    = 'Microsoft.Graph.Identity.SignIns'
            Guid          = '60f889fa-f873-43ad-b7d3-b7fc1273a44f'
        }, @{
            ModuleVersion = '1.20.0'
            ModuleName    = 'Microsoft.Graph.Identity.DirectoryManagement'
            Guid          = 'c767240d-585c-42cb-bb2f-6e76e6d639d4'
        }, @{
            ModuleVersion = '1.20.0'
            ModuleName    = 'Microsoft.Graph.Users'
            Guid          = '71150504-37a3-48c6-82c7-7a00a12168db'
        }, @{
            ModuleVersion = '1.20.0'
            ModuleName    = 'Microsoft.Graph.PersonalContacts'
            Guid          = 'a53e24d0-43dd-43ec-950e-7ac40ea986fc'
        })
    RootModule           = 'O365Synchronizer.psm1'
}