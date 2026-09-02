Describe 'Clear-O365PersonalContact folder removal' {
    InModuleScope O365Synchronizer {
        BeforeEach {
            Mock Write-Color {}
            Mock Get-Command { @{ Name = 'Remove-MgUserContactFolderContact' } }
        }

        Context 'when contacts remain in folder' {
            It 'skips folder removal' {
                $script:FolderContactCall = 0

                Mock Get-MgUserContactFolder {
                    [pscustomobject]@{ Id = 'folder-id' }
                }
                Mock Get-MgUserContactFolderContact {
                    $script:FolderContactCall++
                    if ($script:FolderContactCall -eq 1) {
                        @([pscustomobject]@{
                                Id          = 'contact-1'
                                FileAs      = '11111111-1111-1111-1111-111111111111'
                                DisplayName = 'Contact One'
                            })
                    } else {
                        @([pscustomobject]@{ Id = 'contact-2' })
                    }
                }
                Mock Remove-MgUserContactFolderContact {}
                Mock Remove-MgUserContact {}
                Mock Remove-MgUserContactFolder {}

                Clear-O365PersonalContact -Identity 'user@contoso.com' -FolderName 'O365Sync' -FolderRemove

                Should -Invoke -CommandName Remove-MgUserContactFolder -Times 0
            }
        }

        Context 'when WhatIf is set' {
            It 'skips the empty-folder retry check' {
                $script:FolderContactCall = 0

                Mock Get-MgUserContactFolder {
                    [pscustomobject]@{ Id = 'folder-id' }
                }
                Mock Get-MgUserContactFolderContact {
                    $script:FolderContactCall++
                    @([pscustomobject]@{
                            Id          = 'contact-1'
                            FileAs      = '11111111-1111-1111-1111-111111111111'
                            DisplayName = 'Contact One'
                        })
                }
                Mock Remove-MgUserContactFolderContact {}
                Mock Remove-MgUserContact {}
                Mock Remove-MgUserContactFolder {}

                Clear-O365PersonalContact -Identity 'user@contoso.com' -FolderName 'O365Sync' -FolderRemove -WhatIf

                Should -Invoke -CommandName Get-MgUserContactFolderContact -Times 1
                Should -Invoke -CommandName Remove-MgUserContactFolder -Times 1
            }
        }

        Context 'when folder is empty after removal' {
            It 'removes the folder' {
                $script:FolderContactCall = 0

                Mock Get-MgUserContactFolder {
                    [pscustomobject]@{ Id = 'folder-id' }
                }
                Mock Get-MgUserContactFolderContact {
                    $script:FolderContactCall++
                    if ($script:FolderContactCall -eq 1) {
                        @([pscustomobject]@{
                                Id          = 'contact-1'
                                FileAs      = '11111111-1111-1111-1111-111111111111'
                                DisplayName = 'Contact One'
                            })
                    } else {
                        @()
                    }
                }
                Mock Remove-MgUserContactFolderContact {}
                Mock Remove-MgUserContact {}
                Mock Remove-MgUserContactFolder {}

                Clear-O365PersonalContact -Identity 'user@contoso.com' -FolderName 'O365Sync' -FolderRemove

                Should -Invoke -CommandName Remove-MgUserContactFolder -Times 1
            }
        }

                Context 'when folder name contains a single quote' {
            It 'escapes the folder name in the Graph filter' {
                Mock Get-MgUserContactFolder { throw "Unexpected filter: $Filter" }
                Mock Get-MgUserContactFolder -ParameterFilter { $Filter -eq "DisplayName eq 'O''365Sync'" } {
                    [pscustomobject]@{ Id = 'folder-id' }
                }
                Mock Get-MgUserContactFolderContact {
                    @([pscustomobject]@{
                            Id          = 'contact-1'
                            FileAs      = '11111111-1111-1111-1111-111111111111'
                            DisplayName = 'Contact One'
                        })
                }
                Mock Remove-MgUserContactFolderContact {}

                Clear-O365PersonalContact -Identity 'user@contoso.com' -FolderName "O'365Sync"

                Should -Invoke -CommandName Get-MgUserContactFolder -Times 1 -ParameterFilter { $Filter -eq "DisplayName eq 'O''365Sync'" }
            }
        }
    }
}
