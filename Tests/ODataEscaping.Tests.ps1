Describe 'OData escaping helpers' {
    InModuleScope O365Synchronizer {
        BeforeEach {
            Mock Write-Color {}
        }

        It 'escapes single quotes in Initialize-FolderName lookup filter' {
            Mock Get-MgUserContactFolder { throw "Unexpected filter: $Filter" }
            Mock Get-MgUserContactFolder -ParameterFilter { $Filter -eq "DisplayName eq 'O''365Sync'" } { $null }
            Mock New-MgUserContactFolder { [pscustomobject]@{ Id = 'folder-id' } }

            $result = Initialize-FolderName -UserId 'user@contoso.com' -FolderName "O'365Sync"

            $result.Id | Should -Be 'folder-id'
            Should -Invoke -CommandName Get-MgUserContactFolder -Times 1 -ParameterFilter { $Filter -eq "DisplayName eq 'O''365Sync'" }
            Should -Invoke -CommandName New-MgUserContactFolder -Times 1
        }

        It 'escapes single quotes in Get-O365ExistingUserContacts lookup filter' {
            Mock Get-MgUserContactFolder { throw "Unexpected filter: $Filter" }
            Mock Get-MgUserContactFolder -ParameterFilter { $Filter -eq "DisplayName eq 'O''365Sync'" } {
                [pscustomobject]@{ Id = 'folder-id' }
            }
            Mock Get-MgUserContactFolderContact { @() }

            $result = Get-O365ExistingUserContacts -UserID 'user@contoso.com' -GuidPrefix '' -FolderName "O'365Sync"

            ($result -is [System.Collections.IDictionary]) | Should -BeTrue
            Should -Invoke -CommandName Get-MgUserContactFolder -Times 1 -ParameterFilter { $Filter -eq "DisplayName eq 'O''365Sync'" }
            Should -Invoke -CommandName Get-MgUserContactFolderContact -Times 1
        }
    }
}
