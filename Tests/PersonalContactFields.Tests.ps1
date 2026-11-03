Describe 'Selective personal contact synchronization' {
    InModuleScope O365Synchronizer {
        BeforeAll {
            Initialize-DefaultValuesO365
        }
        BeforeEach {
            $script:Source = [pscustomobject]@{
                Id = '11111111-1111-1111-1111-111111111111'
                DisplayName = 'Directory name'
                GivenName = 'New given name'
                Mail = @('user@contoso.com')
                JobTitle = 'New title'
                Manager = ''
                BusinessPhones = @('123', ' 123 ')
            }
            $script:Contact = [pscustomobject]@{
                Id = 'contact-1'
                Nickname = 'Personal nickname'
                DisplayName = 'Personal name'
                JobTitle = 'Old title'
                Manager = 'Old boss'
                CompanyName = 'Personal company'
                BusinessPhones = @('123', '123')
                EmailAddresses = @([pscustomobject]@{ Address = 'user@contoso.com' })
            }
        }

        It 'updates only selected fields and preserves the existing display name' {
            Mock Set-O365WrapperPersonalContact { [pscustomobject]@{ Success = $true } }
            $result = Set-O365InternalContact -UserID 'owner@contoso.com' -User $script:Source -Contact $script:Contact -SyncField JobTitle,Manager
            $result.Update.Count | Should -Be 2
            $result.Update | Should -Contain 'JobTitle'
            $result.Update | Should -Contain 'Manager'
            Should -Invoke Set-O365WrapperPersonalContact -Times 1 -Exactly -ParameterFilter {
                $JobTitle -eq 'New title' -and $Manager -eq '' -and $DisplayName -eq 'Personal name' -and
                -not $PSBoundParameters.ContainsKey('CompanyName') -and -not $PSBoundParameters.ContainsKey('NickName')
            }
        }

        It 'omits unselected fields when creating a contact and keeps its source marker' {
            Mock New-O365WrapperPersonalContact { $true }
            $result = New-O365InternalContact -UserId 'owner@contoso.com' -User $script:Source -GuidPrefix 'scope:' -SyncField JobTitle,Mail
            $result.Status | Should -Be 'OK'
            Should -Invoke New-O365WrapperPersonalContact -Times 1 -Exactly -ParameterFilter {
                $JobTitle -eq 'New title' -and $Mail -eq 'user@contoso.com' -and
                $FileAs -eq 'scope:11111111-1111-1111-1111-111111111111' -and
                -not $PSBoundParameters.ContainsKey('DisplayName') -and -not $PSBoundParameters.ContainsKey('NickName')
            }
        }

        It 'preserves the contact display name during a name-only update with no source display name' {
            $script:Source.DisplayName = ''
            Mock Set-O365WrapperPersonalContact { [pscustomobject]@{ Success = $true } }
            $null = Set-O365InternalContact -UserID 'owner@contoso.com' -User $script:Source -Contact $script:Contact -SyncField GivenName
            Should -Invoke Set-O365WrapperPersonalContact -Times 1 -Exactly -ParameterFilter {
                $GivenName -eq 'New given name' -and $DisplayName -eq 'Personal name'
            }
        }

        It 'detects repeated target phone values even when the unique values match the source' {
            $result = Compare-UserToContact -UserID 'owner@contoso.com' -ExistingContactGAL $script:Source -Contact $script:Contact -SyncField BusinessPhones
            $result.Update.Count | Should -Be 1
            $result.Update | Should -Contain 'BusinessPhones'
        }

        It 'cleans exact values without guessing phone-number equivalence' {
            $values = @(ConvertTo-CleanContactArray -Values @(' 123 ', '123', '', '+48 123', '+48123'))
            $values.Count | Should -Be 3
            $values[0] | Should -Be '123'
            $values[1] | Should -Be '+48 123'
            $values[2] | Should -Be '+48123'
        }

        It 'rejects empty or contradictory field selections before reading the tenant' {
            Mock Get-O365ExistingMembers { throw 'Should not read tenant' }
            { Sync-O365PersonalContact -UserId 'owner@contoso.com' -SyncField @() } | Should -Throw '*Select All*'
            { Sync-O365PersonalContact -UserId 'owner@contoso.com' -SyncField All,Mail } | Should -Throw '*Select All*'
            Should -Invoke Get-O365ExistingMembers -Times 0 -Exactly
        }

        It 'passes the public field and duplicate options through to the sync engine' {
            Mock Get-O365ExistingMembers { @{ $script:Source.Id = $script:Source } }
            Mock Initialize-FolderName { [pscustomobject]@{ Id = 'folder-1' } }
            Mock Get-O365ExistingUserContacts { [ordered]@{} }
            Mock Sync-InternalO365PersonalContact {}
            Sync-O365PersonalContact -UserId 'owner@contoso.com' -SyncField JobTitle,Mail -RemoveDuplicateContacts -WhatIf
            Should -Invoke Get-O365ExistingUserContacts -Times 1 -Exactly -ParameterFilter { $IncludeDuplicates }
            Should -Invoke Sync-InternalO365PersonalContact -Times 1 -Exactly -ParameterFilter {
                $SyncField.Count -eq 2 -and $SyncField -contains 'JobTitle' -and $SyncField -contains 'Mail' -and $WhatIf
            }
        }

        It 'retains extra managed cards only for explicit duplicate cleanup and previews deletion' {
            $id = '11111111-1111-1111-1111-111111111111'
            Mock Get-MgUserContact {
                [pscustomobject]@{ Id = 'primary'; FileAs = 'scope:11111111-1111-1111-1111-111111111111'; DisplayName = 'Primary' }
                [pscustomobject]@{ Id = 'duplicate'; FileAs = 'scope:11111111-1111-1111-1111-111111111111'; DisplayName = 'Duplicate' }
                [pscustomobject]@{ Id = 'personal'; FileAs = 'Personal contact'; DisplayName = 'Personal' }
                [pscustomobject]@{ Id = 'other-scope'; FileAs = 'other:11111111-1111-1111-1111-111111111111'; DisplayName = 'Other scope' }
            }
            Mock Remove-MgUserContact {}
            $normal = Get-O365ExistingUserContacts -UserID 'owner@contoso.com' -GuidPrefix 'scope:'
            $normal.Count | Should -Be 1
            $cleanup = Get-O365ExistingUserContacts -UserID 'owner@contoso.com' -GuidPrefix 'scope:' -IncludeDuplicates
            $cleanup.Count | Should -Be 2
            $result = @(Remove-O365InternalContact -ExistingUsers @{ $id = $script:Source } -ExistingContacts $cleanup -UserId 'owner@contoso.com' -WhatIf)
            $result.Count | Should -Be 1
            $result[0].Details | Should -Be 'Duplicate managed contact'
            $result[0].Status | Should -Be 'OK (WhatIf)'
            Should -Invoke Remove-MgUserContact -Times 1 -Exactly -ParameterFilter { $ContactId -eq 'duplicate' -and $WhatIf }
        }
    }
}
