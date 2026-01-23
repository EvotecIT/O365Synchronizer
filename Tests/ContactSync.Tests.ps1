Describe 'O365Synchronizer contact sync helpers' {
    InModuleScope O365Synchronizer {
        BeforeAll {
            Initialize-DefaultValuesO365
        }

        Context 'Compare-UserToContact address updates' {
            It 'updates all address fields when any address field changes' {
                $existing = [pscustomobject]@{
                    DisplayName    = 'User One'
                    Mail           = 'user1@example.com'
                    MailNickname   = 'user1'
                    GivenName      = 'User'
                    Surname        = 'One'
                    CompanyName    = 'Evotec'
                    BusinessPhones = '123'
                    MobilePhone    = '111'
                    HomePhone      = '222'
                    JobTitle       = 'Engineer'
                    Country        = 'PL'
                    City           = 'Warsaw'
                    State          = 'Mazovia'
                    Street         = 'Old Street'
                    PostalCode     = '00-000'
                }

                $contact = [pscustomobject]@{
                    Nickname       = 'user1'
                    DisplayName    = 'User One'
                    GivenName      = 'User'
                    Surname        = 'One'
                    EmailAddresses = @([pscustomobject]@{ Address = 'user1@example.com' })
                    BusinessPhones = '123'
                    MobilePhone    = '111'
                    HomePhone      = '222'
                    CompanyName    = 'Evotec'
                    JobTitle       = 'Engineer'
                    BusinessAddress = [pscustomobject]@{
                        CountryOrRegion = 'PL'
                        City            = 'Warsaw'
                        State           = 'Mazovia'
                        Street          = 'New Street'
                        PostalCode      = '00-000'
                    }
                }

                $result = Compare-UserToContact -ExistingContactGAL $existing -Contact $contact -UserID 'user1@example.com'

                $addressProperties = @('City', 'State', 'Street', 'PostalCode', 'Country')
                foreach ($Property in $addressProperties) {
                    $result.Update | Should -Contain $Property
                }
            }
        }

        Context 'New-O365InternalContact require email' {
            It 'skips users without email when RequireEmailAddress is set' {
                Mock New-O365WrapperPersonalContact { throw 'Should not be called' }

                $user = [pscustomobject]@{
                    DisplayName = 'No Mail'
                    Mail        = $null
                    Id          = '00000000-0000-0000-0000-000000000000'
                }

                $result = New-O365InternalContact -UserId 'user@contoso.com' -User $user -GuidPrefix '' -RequireEmailAddress

                $result.Status | Should -Be 'Skipped'
                $result.Skip | Should -Be 'RequireEmailAddress'
            }
        }

        Context 'Set-O365WrapperPersonalContact result' {
            It 'returns success when update succeeds' {
                Mock Update-MgUserContact {}

                $result = Set-O365WrapperPersonalContact -UserId 'user@contoso.com' -ContactId 'contact-id' -DisplayName 'User One'

                $result.Success | Should -BeTrue
                $result.ErrorMessage | Should -Be ''
            }

            It 'returns error message when update fails' {
                Mock Update-MgUserContact { throw 'boom' }

                $result = Set-O365WrapperPersonalContact -UserId 'user@contoso.com' -ContactId 'contact-id' -DisplayName 'User One'

                $result.Success | Should -BeFalse
                $result.ErrorMessage | Should -Match 'boom'
            }
        }

        Context 'Set-O365InternalContact error propagation' {
            It 'preserves update details and returns error on failure' {
                Mock Compare-UserToContact {
                    [pscustomobject]@{
                        UserId      = 'user@contoso.com'
                        Action      = 'Update'
                        DisplayName = 'User One'
                        Mail        = 'user@contoso.com'
                        Update      = @('DisplayName')
                        Skip        = @()
                        Details     = ''
                        Error       = ''
                    }
                }
                Mock Set-O365WrapperPersonalContact {
                    [pscustomobject]@{
                        Success      = $false
                        ErrorMessage = 'update failed'
                    }
                }

                $user = [pscustomobject]@{
                    DisplayName = 'User One'
                    Mail        = 'user@contoso.com'
                }
                $contact = [pscustomobject]@{ Id = 'contact-id' }

                $result = Set-O365InternalContact -UserID 'user@contoso.com' -User $user -Contact $contact

                $result.Status | Should -Be 'Failed'
                $result.Error | Should -Be 'update failed'
                $result.Update | Should -Contain 'DisplayName'
            }
        }
    }
}
