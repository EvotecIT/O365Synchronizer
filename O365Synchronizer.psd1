@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2023 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'This module allows to synchronize users to/from Office 365.'
    FunctionsToExport    = @('Clear-O365PersonalContact', 'Sync-O365PersonalContact')
    GUID                 = '81e907a0-a475-4d6a-a80d-20e9f08ad6b7'
    ModuleVersion        = '0.0.1'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags       = 'windows'
            ProjectUri = 'https://github.com/EvotecIT/O365Synchronizer'
        }
    }
    RequiredModules      = @(@{
            ModuleVersion = '0.0.257'
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        }, @{
            ModuleVersion = '1.0.0'
            ModuleName    = 'Mailozaurr'
            Guid          = '2b0ea9f1-3ff1-4300-b939-106d5da608fa'
        }, @{
            ModuleVersion = '0.0.180'
            ModuleName    = 'PSWriteHTML'
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
        }, @{
            ModuleVersion = '0.87.3'
            ModuleName    = 'PSWriteColor'
            Guid          = '0b0ba5c5-ec85-4c2b-a718-874e55a8bc3f'
        })
    RootModule           = 'O365Synchronizer.psm1'
}